//
//  EnvironmentSettingsSection.swift
//  ExploreRL
//

import SwiftUI

struct EnvironmentSettingsSection: View {
    let definitions: [SettingDefinition]
    @Binding var settings: [String: SettingValue]
    @Binding var validationErrors: Set<String>

    private var visibleDefinitions: [SettingDefinition] {
        definitions.filter { def in
            if def.id == "success_rate" {
                return settings["is_slippery"]?.boolValue ?? true
            }
            return true
        }
    }

    private var groupedDefinitions: [(title: String, items: [SettingDefinition])] {
        var groups: [String: [SettingDefinition]] = [:]
        for def in visibleDefinitions {
            let title = groupTitle(for: def.id)
            groups[title, default: []].append(def)
        }
        let order = ["General", "Map", "Reset", "Settings"]
        let remaining = groups.keys.filter { !order.contains($0) }.sorted()
        let titles = order.filter { groups[$0] != nil } + remaining
        return titles.compactMap { title in
            guard let items = groups[title] else { return nil }
            return (title: title, items: items)
        }
    }

    var body: some View {
        Group {
            if definitions.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Environment Settings",
                        systemImage: "gearshape.slash",
                        description: Text("This environment has no configurable settings.")
                    )
                }
            } else {
                ForEach(groupedDefinitions, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.items) { definition in
                            settingRow(for: definition)
                        }
                    }
                }
            }
        }
        .onAppear {
            updateValidationErrors()
        }
        .onChange(of: settings) { _, _ in
            updateValidationErrors()
        }
    }

    @ViewBuilder
    private func settingRow(for definition: SettingDefinition) -> some View {
        let currentValue = settings[definition.id] ?? definition.defaultValue

        VStack(alignment: .leading, spacing: 4) {
            switch definition.defaultValue {
            case .bool:
                boolSetting(definition: definition, currentValue: currentValue)
            case .float:
                floatSetting(definition: definition, currentValue: currentValue)
            case .string:
                stringSetting(definition: definition, currentValue: currentValue)
            case .int:
                intSetting(definition: definition, currentValue: currentValue)
            }

            if let description = definition.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func boolSetting(definition: SettingDefinition, currentValue: SettingValue) -> some View {
        let isOn = if case .bool(let b) = currentValue { b } else { false }

        Toggle(definition.label, isOn: Binding(
            get: { isOn },
            set: { settings[definition.id] = .bool($0) }
        ))
    }

    @ViewBuilder
    private func floatSetting(definition: SettingDefinition, currentValue: SettingValue) -> some View {
        let value = if case .float(let f) = currentValue { f } else { Float(0) }

        if let range = definition.range {
            VStack(alignment: .leading) {
                HStack {
                    Text(definition.label)
                    Spacer()
                    Text(String(format: "%.2f", value))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { settings[definition.id] = .float(Float($0)) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound)
                )
            }
        } else {
            HStack {
                Text(definition.label)
                Spacer()
                TextField(
                    "Value",
                    value: Binding(
                        get: { value },
                        set: { settings[definition.id] = .float($0) }
                    ),
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
            }
        }
    }

    @ViewBuilder
    private func stringSetting(definition: SettingDefinition, currentValue: SettingValue) -> some View {
        let value = if case .string(let s) = currentValue { s } else { "" }
        let validationMessage = validationMessage(for: definition.id, value: value)

        if let options = definition.options {
            Picker(definition.label, selection: Binding(
                get: { value },
                set: { settings[definition.id] = .string($0) }
            )) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                TextField(
                    definition.label,
                    text: Binding(
                        get: { value },
                        set: { settings[definition.id] = .string($0) }
                    )
                )

                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func validationMessage(for id: String, value: String) -> String? {
        if id == "seed" {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            if UInt64(trimmed) == nil {
                return "Seed must be an unsigned integer."
            }
        }
        if id == "custom_map" {
            return validateCustomMap(value)
        }
        return nil
    }

    private func validateCustomMap(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let rows = trimmed
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let first = rows.first else { return nil }

        let ncol = first.count
        let validTiles: Set<Character> = ["S", "F", "H", "G"]
        var hasStart = false
        var hasGoal = false

        for row in rows {
            if row.count != ncol {
                return "All rows must have the same length."
            }
            for tile in row {
                if !validTiles.contains(tile) {
                    return "Invalid character '\(tile)'. Use S, F, H, G."
                }
                if tile == "S" { hasStart = true }
                if tile == "G" { hasGoal = true }
            }
        }

        if !hasStart { return "Map must contain a start tile (S)." }
        if !hasGoal { return "Map must contain a goal tile (G)." }

        return nil
    }

    private func updateValidationErrors() {
        var errors = Set<String>()
        if let seedValue = settings["seed"]?.stringValue {
            let trimmed = seedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && UInt64(trimmed) == nil {
                errors.insert("seed")
            }
        }
        if let mapValue = settings["custom_map"]?.stringValue {
            if validateCustomMap(mapValue) != nil {
                errors.insert("custom_map")
            }
        }
        validationErrors = errors
    }

    private func groupTitle(for id: String) -> String {
        switch id {
        case "seed":
            return "General"
        case "size",
             "is_slippery",
             "success_rate",
             "hole_probability",
             "custom_map":
            return "Map"
        case "x_init",
             "y_init",
             "low",
             "high",
             "randomize":
            return "Reset"
        default:
            return "Settings"
        }
    }

    @ViewBuilder
    private func intSetting(definition: SettingDefinition, currentValue: SettingValue) -> some View {
        let value = if case .int(let i) = currentValue { i } else { 0 }

        if let range = definition.range {
            VStack(alignment: .leading) {
                HStack {
                    Text(definition.label)
                    Spacer()
                    Text("\(value)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { settings[definition.id] = .int(Int($0.rounded())) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 1
                )
            }
        } else {
            HStack {
                Text(definition.label)
                Spacer()
                TextField(
                    "Value",
                    value: Binding(
                        get: { value },
                        set: { settings[definition.id] = .int($0) }
                    ),
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
            }
        }
    }
}

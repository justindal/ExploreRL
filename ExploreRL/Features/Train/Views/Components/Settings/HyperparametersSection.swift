//
//  HyperparametersSection.swift
//  ExploreRL
//

import SwiftUI

struct HyperparametersSection: View {
    @Binding var config: TrainingConfig
    @Binding var validationErrors: Set<String>
    @State private var stringValues: [String: String] = [:]
    @State private var expandedGroups: Set<String> = []

    private var definitions: [HyperparameterDefinition] {
        HyperparameterConfig.definitions(for: config.algorithm)
    }

    private var accessor: HyperparameterAccessor {
        HyperparameterAccessor(config: config)
    }

    private var groupedDefinitions: [(title: String, items: [HyperparameterDefinition])] {
        let visible = definitions.filter { isVisible($0) }
        var groups: [String: [HyperparameterDefinition]] = [:]
        for def in visible {
            let title = groupTitle(for: def.id)
            groups[title, default: []].append(def)
        }
        let ordered = groupOrder
        let remaining = groups.keys.filter { !ordered.contains($0) }.sorted()
        let titles = ordered.filter { groups[$0] != nil } + remaining
        return titles.compactMap { title in
            guard let items = groups[title] else { return nil }
            return (title: title, items: items)
        }
    }

    var body: some View {
        ForEach(groupedDefinitions, id: \.title) { group in
            Section {
                DisclosureGroup(
                    isExpanded: bindingForGroup(group.title),
                    content: {
                        ForEach(group.items) { def in
                            hyperparameterRow(def)
                        }
                    },
                    label: {
                        Text(group.title)
                    }
                )
            }
        }
        .onAppear {
            syncStringValues()
            updateValidationErrors()
            ensureExpandedGroups()
        }
        .onChange(of: config.algorithm) { _, _ in
            syncStringValues()
            updateValidationErrors()
            ensureExpandedGroups()
        }
        .onChange(of: config) { _, _ in
            updateValidationErrors()
        }
        .onChange(of: stringValues) { _, _ in
            updateValidationErrors()
        }
    }

    @ViewBuilder
    private func hyperparameterRow(_ def: HyperparameterDefinition) -> some View {
        switch def.type {
        case .double(_, let range, let step):
            doubleHyperparameter(def, range: range, step: step)
        case .float(_, let range, _):
            floatHyperparameter(def, range: range)
        case .int(_, let range):
            intHyperparameter(def, range: range)
        case .bool(_):
            boolHyperparameter(def)
        case .string(_, let options):
            stringHyperparameter(def, options: options)
        }
    }

    @ViewBuilder
    private func doubleHyperparameter(
        _ def: HyperparameterDefinition,
        range: ClosedRange<Double>?,
        step: Double?
    ) -> some View {
        let value = accessor.doubleValue(for: def.id)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(def.label)
                Spacer()
                Text(String(format: "%.3f", value))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if let range = range {
                let binding = Binding(
                    get: { value },
                    set: { newVal in
                        HyperparameterAccessor.setDouble(id: def.id, value: newVal, on: &config)
                    }
                )

                if let step {
                    Slider(value: binding, in: range, step: step)
                } else {
                    Slider(value: binding, in: range)
                }
            }

            if let desc = def.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func floatHyperparameter(
        _ def: HyperparameterDefinition,
        range _: ClosedRange<Float>?
    ) -> some View {
        let value = accessor.floatValue(for: def.id)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(def.label)
                Spacer()
                TextField(
                    "Value",
                    value: Binding(
                        get: { value },
                        set: { newVal in
                            HyperparameterAccessor.setFloat(id: def.id, value: newVal, on: &config)
                        }
                    ),
                    format: .number.precision(.significantDigits(1...4))
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .multilineTextAlignment(.trailing)
            }

            if let desc = def.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func intHyperparameter(
        _ def: HyperparameterDefinition,
        range _: ClosedRange<Int>?
    ) -> some View {
        let value = accessor.intValue(for: def.id)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(def.label)
                Spacer()
                TextField(
                    "Value",
                    value: Binding(
                        get: { value },
                        set: { newVal in
                            HyperparameterAccessor.setInt(id: def.id, value: newVal, on: &config)
                        }
                    ),
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .multilineTextAlignment(.trailing)
            }

            if let desc = def.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func boolHyperparameter(_ def: HyperparameterDefinition) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(def.label, isOn: Binding(
                get: { accessor.boolValue(for: def.id) },
                set: { newVal in
                    HyperparameterAccessor.setBool(id: def.id, value: newVal, on: &config)
                }
            ))

            if let desc = def.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func stringHyperparameter(
        _ def: HyperparameterDefinition,
        options: [String]?
    ) -> some View {
        let value = stringValues[def.id] ?? accessor.stringValue(for: def.id)
        let validationMessage = validationMessage(for: def.id, value: value)

        VStack(alignment: .leading, spacing: 4) {
            if let options {
                Picker(def.label, selection: Binding(
                    get: { value },
                    set: { newVal in
                        stringValues[def.id] = newVal
                        HyperparameterAccessor.setString(id: def.id, value: newVal, on: &config)
                    }
                )) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            } else {
                HStack {
                    Text(def.label)
                    Spacer()
                    TextField(
                        "Value",
                        text: Binding(
                            get: { value },
                            set: { newVal in
                                stringValues[def.id] = newVal
                                if isValidStringValue(id: def.id, value: newVal) {
                                    HyperparameterAccessor.setString(
                                        id: def.id,
                                        value: newVal,
                                        on: &config
                                    )
                                }
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)
                    .multilineTextAlignment(.trailing)
                }
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let desc = def.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func validationMessage(for id: String, value: String) -> String? {
        if !isVisibleId(id) {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch id {
        case "netArch":
            return validateIntList(trimmed) ? nil : "Use comma-separated positive integers."
        case "criticNetArch":
            return validateIntList(trimmed) ? nil : "Use comma-separated positive integers."
        case "learningRateMilestones":
            return validateMilestones(trimmed) ? nil : "Use values between 0 and 1, e.g. 0.5,0.75."
        default:
            return nil
        }
    }

    private func isValidStringValue(id: String, value: String) -> Bool {
        validationMessage(for: id, value: value) == nil
    }

    private func validateIntList(_ value: String) -> Bool {
        if value.isEmpty { return false }
        let parts = value.split { char in
            char == "," || char == " " || char == "\n" || char == "\t" || char == ";"
        }
        if parts.isEmpty { return false }
        return parts.allSatisfy { part in
            if let intValue = Int(part) {
                return intValue > 0
            }
            return false
        }
    }

    private func validateMilestones(_ value: String) -> Bool {
        if value.isEmpty { return false }
        let parts = value.split { char in
            char == "," || char == " " || char == "\n" || char == "\t" || char == ";"
        }
        if parts.isEmpty { return false }
        return parts.allSatisfy { part in
            if let doubleValue = Double(part) {
                return doubleValue > 0 && doubleValue < 1
            }
            return false
        }
    }

    private func syncStringValues() {
        var next: [String: String] = [:]
        for def in definitions {
            if case .string = def.type {
                next[def.id] = stringValues[def.id] ?? accessor.stringValue(for: def.id)
            }
        }
        stringValues = next
    }

    private func updateValidationErrors() {
        var errors: Set<String> = []
        for def in definitions {
            guard case .string = def.type else { continue }
            if !isVisible(def) { continue }
            let value = stringValues[def.id] ?? accessor.stringValue(for: def.id)
            if !isValidStringValue(id: def.id, value: value) {
                errors.insert(def.id)
            }
        }
        validationErrors = errors
    }

    private func bindingForGroup(_ title: String) -> Binding<Bool> {
        Binding(
            get: { expandedGroups.contains(title) },
            set: { isExpanded in
                if isExpanded {
                    expandedGroups.insert(title)
                } else {
                    expandedGroups.remove(title)
                }
            }
        )
    }

    private func ensureExpandedGroups() {
        if !expandedGroups.isEmpty { return }
        let defaults: [String]
        switch config.algorithm {
        case .dqn:
            defaults = ["Training", "Epsilon/Exploration", "Learning Rate", "Networks"]
        case .sac:
            defaults = ["Training", "Epsilon/Exploration", "Learning Rate", "Networks", "Entropy"]
        case .qLearning, .sarsa:
            defaults = ["Learning Rate", "Epsilon/Exploration"]
        }
        expandedGroups = Set(defaults)
    }

    private var groupOrder: [String] {
        switch config.algorithm {
        case .dqn:
            return [
                "Learning Rate",
                "Training",
                "Epsilon/Exploration",
                "Discount & Targets",
                "Networks",
                "Optimizer",
                "Replay Buffer"
            ]
        case .sac:
            return [
                "Learning Rate",
                "Training",
                "Epsilon/Exploration",
                "Discount & Targets",
                "Networks",
                "Entropy",
                "Optimizer",
                "Replay Buffer"
            ]
        case .qLearning, .sarsa:
            return [
                "Learning Rate",
                "Epsilon/Exploration",
                "Discount & Targets"
            ]
        }
    }

    private func groupTitle(for id: String) -> String {
        switch id {
        case "learningRate",
             "learningRateSchedule",
             "learningRateFinal",
             "learningRateDecayRate",
             "learningRateMinValue",
             "learningRateMilestones",
             "learningRateGamma",
             "warmupEnabled",
             "warmupFraction",
             "warmupInitialValue":
            return "Learning Rate"
        case "batchSize",
             "bufferSize",
             "learningStarts",
             "trainFrequency",
             "trainFrequencyUnit",
             "gradientSteps",
             "gradientStepsMode":
            return "Training"
        case "gamma",
             "tau",
             "targetUpdateInterval":
            return "Discount & Targets"
        case "explorationFraction",
             "explorationInitialEps",
             "explorationFinalEps",
             "epsilon",
             "epsilonDecay",
             "minEpsilon",
             "useSDE",
             "useSDEAtWarmup",
             "sdeSampleFreq",
             "logStdInit",
             "fullStd",
             "clipMean":
            return "Epsilon/Exploration"
        case "netArch",
             "activation",
             "normalizeImages",
             "useSeparateNetworks",
             "criticNetArch",
             "nCritics",
             "shareFeaturesExtractor",
             "criticActivation",
             "criticNormalizeImages":
            return "Networks"
        case "autoEntropyTuning",
             "autoEntropyInit",
             "fixedEntCoef",
             "useTargetEntropy",
             "targetEntropy":
            return "Entropy"
        case "maxGradNorm",
             "optimizerBeta1",
             "optimizerBeta2",
             "optimizerEps",
             "optimizerActorBeta1",
             "optimizerActorBeta2",
             "optimizerActorEps",
             "optimizerCriticBeta1",
             "optimizerCriticBeta2",
             "optimizerCriticEps",
             "optimizerEntropyBeta1",
             "optimizerEntropyBeta2",
             "optimizerEntropyEps":
            return "Optimizer"
        case "optimizeMemoryUsage",
             "handleTimeoutTermination":
            return "Replay Buffer"
        default:
            return "Epsilon/Exploration"
        }
    }

    private func isVisible(_ def: HyperparameterDefinition) -> Bool {
        isVisibleId(def.id)
    }

    private func isVisibleId(_ id: String) -> Bool {
        switch id {
        case "learningRateFinal":
            return currentLearningRateSchedule == "linear"
        case "learningRateDecayRate":
            return currentLearningRateSchedule == "exponential"
        case "learningRateMinValue":
            return currentLearningRateSchedule == "cosine"
        case "learningRateMilestones", "learningRateGamma":
            return currentLearningRateSchedule == "step"
        case "warmupFraction", "warmupInitialValue":
            return isWarmupEnabled
        case "autoEntropyInit":
            return config.algorithm == .sac && config.sac.autoEntropyTuning
        case "fixedEntCoef":
            return config.algorithm == .sac && !config.sac.autoEntropyTuning
        case "targetEntropy":
            return config.algorithm == .sac && config.sac.useTargetEntropy
        case "optimizerEntropyBeta1",
             "optimizerEntropyBeta2",
             "optimizerEntropyEps":
            return config.algorithm == .sac && config.sac.autoEntropyTuning
        case "criticNetArch":
            return config.algorithm == .sac && config.sac.useSeparateNetworks
        case "useSDEAtWarmup",
             "sdeSampleFreq",
             "logStdInit",
             "fullStd",
             "clipMean":
            return config.algorithm == .sac && config.sac.useSDE
        case "nCritics",
             "shareFeaturesExtractor",
             "criticActivation",
             "criticNormalizeImages",
             "useSeparateNetworks",
             "autoEntropyTuning",
             "useTargetEntropy",
             "useSDE":
            return config.algorithm == .sac
        default:
            return true
        }
    }

    private var currentLearningRateSchedule: String {
        switch config.algorithm {
        case .dqn:
            return config.dqn.learningRateSchedule
        case .sac:
            return config.sac.learningRateSchedule
        case .qLearning, .sarsa:
            return "constant"
        }
    }

    private var isWarmupEnabled: Bool {
        switch config.algorithm {
        case .dqn:
            return config.dqn.warmupEnabled
        case .sac:
            return config.sac.warmupEnabled
        case .qLearning, .sarsa:
            return false
        }
    }
}

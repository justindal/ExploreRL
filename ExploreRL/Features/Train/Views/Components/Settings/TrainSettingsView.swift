//
//  TrainSettingsView.swift
//  ExploreRL
//

import Gymnazo
import MLX
import SwiftUI

struct TrainSettingsView: View {
    let envID: String
    @Bindable var vm: TrainViewModel
    @Environment(\.dismiss) private var dismiss
    var showsDismissButton: Bool = true
    @State private var selectedTab: SettingsTab = .environment
    @State private var showResetAlert = false

    @State private var localEnvSettings: [String: SettingValue]
    @State private var localTrainingConfig: TrainingConfig
    @State private var appliedEnvSettings: [String: SettingValue]
    @State private var appliedTrainingConfig: TrainingConfig
    @State private var envValidationErrors: Set<String> = []
    @State private var trainingValidationErrors: Set<String> = []
    @State private var scheduledResetTask: Task<Void, Never>?

    init(
        envID: String,
        vm: TrainViewModel,
        showsDismissButton: Bool = true
    ) {
        self.envID = envID
        self.vm = vm
        self.showsDismissButton = showsDismissButton
        let config = vm.trainingConfig(for: envID)
        let settings = vm.settings(for: envID)
        _localTrainingConfig = State(initialValue: config)
        _localEnvSettings = State(initialValue: settings)
        _appliedTrainingConfig = State(initialValue: config)
        _appliedEnvSettings = State(initialValue: settings)
    }

    enum SettingsTab: String, CaseIterable {
        case environment = "Environment"
        case training = "Training"
    }

    private var envDefinitions: [SettingDefinition] {
        EnvSettingsConfig.settings(for: envID)
    }

    private var availableAlgorithms: [AlgorithmType] {
        guard let env = vm.env(for: envID) else {
            return AlgorithmType.allCases
        }
        return vm.availableAlgorithms(for: env)
    }

    private var supportsImageNormalization: Bool {
        guard let env = vm.env(for: envID) else {
            return false
        }
        return hasImageObservations(in: env.observationSpace)
    }

    private var navTitle: String {
        if let title = vm.env(for: envID)?.spec?.displayName {
            return "\(title) Settings"
        }
        return "Environment Settings"
    }

    private var settingsTabOptions: [InspectorPicker<SettingsTab>.Option] {
        SettingsTab.allCases.map { tab in
            InspectorPicker<SettingsTab>.Option(
                value: tab,
                title: tab.rawValue
            )
        }
    }

    private var parametersLocked: Bool {
        let state = vm.trainingState(for: envID)
        switch state.status {
        case .training, .paused, .completed:
            return true
        case .failed:
            return state.currentTimestep > 0 || state.hasHistory
        case .idle:
            return state.currentTimestep > 0 || state.hasHistory
        }
    }

    private var canApplyTrainingConfig: Bool {
        let seedValue = localTrainingConfig.seed.trimmingCharacters(in: .whitespacesAndNewlines)
        let seedIsValid = seedValue.isEmpty || UInt64(seedValue) != nil
        return seedIsValid && trainingValidationErrors.isEmpty
    }

    private var canApplyEnvironmentSettings: Bool {
        if !envValidationErrors.isEmpty {
            return false
        }
        if let seedValue = localEnvSettings["seed"]?.stringValue {
            let trimmed = seedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && UInt64(trimmed) == nil {
                return false
            }
        }
        if let customMap = localEnvSettings["custom_map"]?.stringValue {
            if validateCustomMap(customMap) != nil {
                return false
            }
        }
        return true
    }

    var body: some View {
        if showsDismissButton {
            NavigationStack {
                settingsForm
                    .navigationTitle(navTitle)
            }
        } else {
            settingsForm
        }
    }

    private var settingsForm: some View {
        Form {
            Section {
                InspectorPicker(
                    selection: $selectedTab,
                    options: settingsTabOptions
                )
                #if os(iOS)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                #endif
            }

            Group {
                switch selectedTab {
                case .environment:
                    EnvironmentSettingsSection(
                        definitions: envDefinitions,
                        settings: $localEnvSettings,
                        validationErrors: $envValidationErrors
                    )
                case .training:
                    TrainingSettingsSection(
                        availableAlgorithms: availableAlgorithms,
                        supportsImageNormalization: supportsImageNormalization,
                        config: $localTrainingConfig,
                        validationErrors: $trainingValidationErrors
                    )
                }
            }
            .disabled(parametersLocked)

            Section {
                Button("Reset to Defaults", role: .destructive) {
                    showResetAlert = true
                }
            }
            .disabled(parametersLocked)

            if parametersLocked {
                Section {
                    Text("Parameters are locked once a run has started. Reset training to edit settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        #if os(macOS)
            .formStyle(.grouped)
            .modify(if: showsDismissButton) { content in
                content.frame(minWidth: 420, idealWidth: 520, minHeight: 520)
            }
        #endif
        .toolbar {
            if showsDismissButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .alert("Reset to Defaults?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will reset \(selectedTab.rawValue.lowercased()) settings to their default values."
            )
        }
        .onChange(of: localTrainingConfig.algorithm) { oldValue, newValue in
            guard oldValue != newValue else { return }
            guard !parametersLocked else { return }
            applyAlgorithmDefaultsIfNeeded(from: oldValue, to: newValue)
        }
        .onChange(of: localEnvSettings) { _, _ in
            applySettingsIfPossible()
        }
        .onChange(of: localTrainingConfig) { _, _ in
            applySettingsIfPossible()
        }
        .onChange(of: envValidationErrors) { _, _ in
            applySettingsIfPossible()
        }
        .onChange(of: trainingValidationErrors) { _, _ in
            applySettingsIfPossible()
        }
        .onDisappear {
            scheduledResetTask?.cancel()
            scheduledResetTask = nil
        }
    }

    private func resetToDefaults() {
        guard !parametersLocked else { return }
        switch selectedTab {
        case .environment:
            var defaults: [String: SettingValue] = [:]
            for definition in envDefinitions {
                defaults[definition.id] = definition.defaultValue
            }
            localEnvSettings = defaults
        case .training:
            localTrainingConfig = EnvironmentDefaults.config(for: envID)
        }
    }

    private func applySettingsIfPossible() {
        guard !parametersLocked else { return }
        var didApply = false

        if canApplyEnvironmentSettings, localEnvSettings != appliedEnvSettings {
            for (key, value) in localEnvSettings {
                vm.updateSetting(for: envID, key: key, value: value)
            }
            appliedEnvSettings = localEnvSettings
            didApply = true
        }

        if canApplyTrainingConfig, localTrainingConfig != appliedTrainingConfig {
            vm.updateTrainingConfig(for: envID) { config in
                config = localTrainingConfig
            }
            appliedTrainingConfig = localTrainingConfig
            didApply = true
        }

        if didApply {
            scheduleReset()
        }
    }

    private func scheduleReset() {
        scheduledResetTask?.cancel()
        let id = envID
        scheduledResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await vm.resetTraining(for: id)
        }
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

    private func applyAlgorithmDefaultsIfNeeded(
        from previousAlgorithm: AlgorithmType,
        to algorithm: AlgorithmType
    ) {
        let baseDefaults = TrainingConfig()
        let envDefaults = EnvironmentDefaults.config(for: envID)
        let previousTimestepsDefault = EnvironmentDefaults.totalTimestepsDefault(
            for: envID,
            algorithm: previousAlgorithm
        )
        let nextTimestepsDefault = EnvironmentDefaults.totalTimestepsDefault(
            for: envID,
            algorithm: algorithm
        )
        if localTrainingConfig.totalTimesteps == previousTimestepsDefault
            || localTrainingConfig.totalTimesteps == baseDefaults.totalTimesteps
        {
            localTrainingConfig.totalTimesteps = nextTimestepsDefault
        }
        switch algorithm {
        case .qLearning, .sarsa:
            if localTrainingConfig.tabular == baseDefaults.tabular {
                localTrainingConfig.tabular = envDefaults.tabular
            }
        case .dqn:
            if localTrainingConfig.dqn == baseDefaults.dqn {
                localTrainingConfig.dqn = envDefaults.dqn
            }
        case .ppo:
            if localTrainingConfig.ppo == baseDefaults.ppo {
                localTrainingConfig.ppo = envDefaults.ppo
            }
        case .sac:
            if localTrainingConfig.sac == baseDefaults.sac {
                localTrainingConfig.sac = envDefaults.sac
            }
        case .td3:
            if localTrainingConfig.td3 == baseDefaults.td3 {
                localTrainingConfig.td3 = envDefaults.td3
            }
        }
    }

    private func hasImageObservations(in space: any Space) -> Bool {
        if let box = boxSpace(from: space) {
            return box.dtype == .uint8 && box.shape?.count == 3
        }
        if let anySpace = space as? AnySpace {
            return hasImageObservations(in: anySpace.base)
        }
        if let dict = space as? Dict {
            return dict.spaces.values.contains { hasImageObservations(in: $0) }
        }
        if let tuple = space as? Tuple {
            return tuple.spaces.contains { hasImageObservations(in: $0) }
        }
        return false
    }
}

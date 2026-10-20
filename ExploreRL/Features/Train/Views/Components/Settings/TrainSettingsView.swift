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
    @State private var resetGeneration = 0

    @State private var localEnvSettings: [String: SettingValue]
    @State private var localTrainingConfig: TrainingConfig
    @State private var appliedEnvSettings: [String: SettingValue]
    @State private var appliedTrainingConfig: TrainingConfig
    @State private var envValidationErrors: Set<String> = []
    @State private var trainingValidationErrors: Set<String> = []
    @State private var isApplying = false
    @State private var applyError: String?
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
        return vm.availableAlgorithms(for: envID, env: env)
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

    private var hasProgress: Bool {
        vm.trainingState(for: envID).currentTimestep > 0
    }

    private var parametersLocked: Bool {
        vm.trainingTasks[envID] != nil || vm.snapshottingEnvs.contains(envID)
            || vm.isResetting(id: envID) || isApplying
    }

    private var canApplyTrainingConfig: Bool {
        let seedValue = localTrainingConfig.seed.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let seedIsValid = seedValue.isEmpty || UInt64(seedValue) != nil
        return seedIsValid && trainingValidationErrors.isEmpty
            && localTrainingConfig.totalTimesteps >= max(1, vm.trainingState(for: envID).currentTimestep)
            && localTrainingConfig.totalTimesteps <= 1_000_000_000
    }

    private var canApplyEnvironmentSettings: Bool {
        if !envValidationErrors.isEmpty {
            return false
        }
        if let seedValue = localEnvSettings["seed"]?.stringValue {
            let trimmed = seedValue.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
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
        settingsContainer
            #if os(macOS)
                .modify(if: showsDismissButton) { content in
                    content
                    .formStyle(.grouped)
                    .frame(minWidth: 420, idealWidth: 520, minHeight: 520)
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
            .alert("Could Not Apply Settings", isPresented: .init(
                get: { applyError != nil }, set: { if !$0 { applyError = nil } }
            )) {} message: { Text(applyError ?? "") }
            .onChange(of: vm.trainingConfigs[envID]) { _, _ in
                guard localTrainingConfig == appliedTrainingConfig else { return }
                localTrainingConfig = vm.trainingConfig(for: envID)
                appliedTrainingConfig = localTrainingConfig
            }
            .onChange(of: localTrainingConfig.algorithm) { oldValue, newValue in
                guard oldValue != newValue else { return }
                guard !parametersLocked else { return }
                applyAlgorithmDefaultsIfNeeded(from: oldValue, to: newValue)
            }
            .onChange(of: availableAlgorithms, initial: true) { _, algorithms in
                guard let first = algorithms.first else { return }
                guard !algorithms.contains(localTrainingConfig.algorithm) else { return }
                localTrainingConfig.algorithm = first
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
                vm.invalidSettingsEnvs.remove(envID)
                vm.unappliedSettingsEnvs.remove(envID)
            }
    }

    @ViewBuilder
    private var settingsContainer: some View {
        #if os(macOS)
            if showsDismissButton {
                Form {
                    settingsContent
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        settingsContent
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .headerProminence(.increased)
                .environment(\.isInspectorStyle, true)
            }
        #else
            Form {
                settingsContent
            }
        #endif
    }

    @ViewBuilder
    private var settingsContent: some View {
        SettingsSection {
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
                .disabled(hasProgress)
            case .training:
                if envID == MetroRunnerSettings.id, localTrainingConfig.algorithm == .ppo {
                    SettingsSection {
                        Menu("Metro PPO Presets") {
                            ForEach(MetroRunnerTrainingPreset.allCases) { preset in
                                Button(preset.rawValue) {
                                    localTrainingConfig = preset.applying(
                                        to: localTrainingConfig,
                                        currentStep: vm.trainingState(for: envID).currentTimestep
                                    )
                                    resetGeneration += 1
                                }
                            }
                        }
                    } footer: {
                        Text("Starting points to compare across seeds. Longer Rollout uses 2,048 steps per update; Fine-Tuning lowers learning rate and exploration. Neither is a measured optimum. Disable rendering for faster training.")
                    }
                }
                TrainingSettingsSection(
                    availableAlgorithms: availableAlgorithms,
                    supportsImageNormalization: supportsImageNormalization,
                    config: $localTrainingConfig,
                    validationErrors: $trainingValidationErrors,
                    isContinuing: hasProgress
                )
            }
        }
        .id("\(selectedTab.rawValue):\(resetGeneration)")
        .disabled(parametersLocked)

        SettingsSection {
            Button("Reset to Defaults", role: .destructive) {
                showResetAlert = true
            }
        }
        .disabled(parametersLocked || hasProgress)

        if hasProgress {
            continuationSection
        } else if parametersLocked {
            SettingsSection {
                Text(
                    "Pause training to edit the next training segment."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
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
        resetGeneration += 1
    }

    private var continuationSection: some View {
        SettingsSection {
            Button(isApplying ? "Applying Changes…" : "Apply Changes") {
                isApplying = true
                Task {
                    defer { isApplying = false }
                    do {
                        try await vm.applyContinuationConfig(localTrainingConfig, for: envID)
                        appliedTrainingConfig = localTrainingConfig
                        vm.invalidSettingsEnvs.remove(envID)
                        vm.unappliedSettingsEnvs.remove(envID)
                    } catch {
                        applyError = error.localizedDescription
                    }
                }
            }
            .disabled(parametersLocked || !canApplyTrainingConfig || localTrainingConfig == appliedTrainingConfig)
            if localTrainingConfig != appliedTrainingConfig {
                Button("Discard Changes") { localTrainingConfig = appliedTrainingConfig }
                    .disabled(parametersLocked)
            }
            if !canApplyTrainingConfig {
                Text("Use a valid step target that includes the steps already trained.")
                    .font(.caption).foregroundStyle(.red)
            }
        } footer: {
            Text("Pause to change the step target, visualization and supported learning settings. Algorithm, seed, network and environment stay fixed. Tuning preserves learned weights and history, and starts a fresh optimizer.")
        }
    }

    private func applySettingsIfPossible() {
        guard !parametersLocked else { return }
        if hasProgress {
            if canApplyTrainingConfig {
                vm.invalidSettingsEnvs.remove(envID)
            } else {
                vm.invalidSettingsEnvs.insert(envID)
            }
            if localTrainingConfig == appliedTrainingConfig {
                vm.unappliedSettingsEnvs.remove(envID)
            } else {
                vm.unappliedSettingsEnvs.insert(envID)
            }
            return
        }
        if canApplyEnvironmentSettings && canApplyTrainingConfig {
            vm.invalidSettingsEnvs.remove(envID)
        } else {
            vm.invalidSettingsEnvs.insert(envID)
        }
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

        let rows =
            trimmed
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
        let previousTimestepsDefault =
            EnvironmentDefaults.totalTimestepsDefault(
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

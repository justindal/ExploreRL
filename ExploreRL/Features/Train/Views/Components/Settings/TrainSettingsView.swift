//
//  TrainSettingsView.swift
//  ExploreRL
//

import Gymnazo
import SwiftUI

struct TrainSettingsView: View {
    let envID: String
    @Bindable var vm: TrainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .environment
    @State private var showDiscardAlert = false
    @State private var showResetAlert = false

    @State private var localEnvSettings: [String: SettingValue]
    @State private var localTrainingConfig: TrainingConfig
    @State private var initialEnvSettings: [String: SettingValue]
    @State private var initialTrainingConfig: TrainingConfig
    @State private var envValidationErrors: Set<String> = []
    @State private var trainingValidationErrors: Set<String> = []

    init(envID: String, vm: TrainViewModel) {
        self.envID = envID
        self.vm = vm
        let config = vm.trainingConfig(for: envID)
        let settings = vm.settings(for: envID)
        _localTrainingConfig = State(initialValue: config)
        _localEnvSettings = State(initialValue: settings)
        _initialTrainingConfig = State(initialValue: config)
        _initialEnvSettings = State(initialValue: settings)
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

    private var hasEnvChanges: Bool {
        localEnvSettings != initialEnvSettings
    }

    private var hasTrainingChanges: Bool {
        localTrainingConfig != initialTrainingConfig
    }

    private var hasChanges: Bool {
        hasEnvChanges || hasTrainingChanges
    }

    private var hasValidationErrors: Bool {
        !envValidationErrors.isEmpty || !trainingValidationErrors.isEmpty
    }

    private var navTitle: String {
        if let title = vm.env(for: envID)?.spec?.displayName {
            return "\(title) Settings"
        }
        return "Environment Settings"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Settings", selection: $selectedTab) {
                        ForEach(SettingsTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    #if os(macOS)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    #else
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    #endif
                }

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
                        config: $localTrainingConfig,
                        validationErrors: $trainingValidationErrors
                    )
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .navigationTitle(navTitle)
            #if os(macOS)
                .formStyle(.grouped)
                .frame(minWidth: 420, idealWidth: 520, minHeight: 520)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!hasChanges || hasValidationErrors)
                }
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "You have unsaved changes. Are you sure you want to discard them?"
                )
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
        }
    }

    private func saveChanges() {
        if hasValidationErrors { return }
        vm.updateTrainingConfig(for: envID) { config in
            config = localTrainingConfig
        }

        for (key, value) in localEnvSettings {
            vm.updateSetting(for: envID, key: key, value: value)
        }

        dismiss()
        if hasChanges {
            Task { await vm.resetTraining(for: envID) }
        }
    }

    private func resetToDefaults() {
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
}

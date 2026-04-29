//
//  TrainingSettingsSection.swift
//  ExploreRL
//

import SwiftUI

struct TrainingSettingsSection: View {
    let availableAlgorithms: [AlgorithmType]
    let supportsImageNormalization: Bool
    @Binding var config: TrainingConfig
    @Binding var validationErrors: Set<String>
    @State private var hyperparameterErrors: Set<String> = []

    var body: some View {
        Group {
            algorithmSection
            trainingSection
            renderSection
            HyperparametersSection(
                config: $config,
                supportsImageNormalization: supportsImageNormalization,
                validationErrors: $hyperparameterErrors
            )
        }
        .onAppear {
            updateValidationErrors()
        }
        .onChange(of: hyperparameterErrors) { _, _ in
            updateValidationErrors()
        }
        .onChange(of: config.seed) { _, _ in
            updateValidationErrors()
        }
    }

    @ViewBuilder
    private var algorithmSection: some View {
        SettingsSection("Algorithm") {
            Picker("Algorithm", selection: $config.algorithm) {
                ForEach(availableAlgorithms) { algo in
                    Text(algo.rawValue).tag(algo)
                }
            }
        } footer: {
            algorithmDescription
        }
    }

    @ViewBuilder
    private var algorithmDescription: some View {
        switch config.algorithm {
        case .qLearning:
            Text("Off-policy tabular algorithm. Uses max Q-value for updates.")
        case .sarsa:
            Text(
                "On-policy tabular algorithm. Uses actual next action for updates."
            )
        case .dqn:
            Text("Deep Q-Network with experience replay and target network.")
        case .ppo:
            Text("Proximal Policy Optimization with clipped policy updates.")
        case .sac:
            Text(
                "Soft Actor-Critic for continuous control with entropy regularization."
            )
        case .td3:
            Text(
                "Twin Delayed DDPG for continuous control with clipped double Q-learning."
            )
        }
    }

    @ViewBuilder
    private var trainingSection: some View {
        SettingsSection("Training") {
            HStack {
                Text("Total Timesteps")
                Spacer()
                TextField(
                    "Timesteps",
                    value: $config.totalTimesteps,
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .multilineTextAlignment(.trailing)
            }

            let seedValue = config.seed.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let seedIsValid = seedValue.isEmpty || UInt64(seedValue) != nil

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Seed")
                    Spacer()
                    TextField("Optional", text: $config.seed)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                        .multilineTextAlignment(.trailing)
                }

                if !seedIsValid {
                    Text("Seed must be an unsigned integer.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private var renderSection: some View {
        SettingsSection("Visualization") {
            Toggle("Render During Training", isOn: $config.renderDuringTraining)

            if config.renderDuringTraining {
                let sliderBinding = Binding<Double>(
                    get: {
                        config.renderFPS <= 0
                            ? 121 : Double(min(120, config.renderFPS))
                    },
                    set: { value in
                        let v = Int(value.rounded())
                        config.renderFPS = v >= 121 ? 0 : max(1, min(120, v))
                    }
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Render FPS")
                            .lineLimit(1)
                        Spacer()
                        Text(
                            config.renderFPS <= 0
                                ? "Unlimited" : "\(config.renderFPS) fps"
                        )
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .frame(width: 120, alignment: .trailing)
                    }
                    Slider(
                        value: sliderBinding,
                        in: 1...121
                    )
                }
            }
        } footer: {
            Text(
                "Live rendering shows the environment state during training but may slow down training speed."
            )
        }
    }

    private func updateValidationErrors() {
        var errors = hyperparameterErrors
        let seedValue = config.seed.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !seedValue.isEmpty && UInt64(seedValue) == nil {
            errors.insert("seed")
        } else {
            errors.remove("seed")
        }
        validationErrors = errors
    }
}

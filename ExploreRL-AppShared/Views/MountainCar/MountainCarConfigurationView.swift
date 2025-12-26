//
//  MountainCarConfigurationView.swift
//

import SwiftUI

struct MountainCarConfigurationView: View {
    @Bindable var runner: MountainCarRunner
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ConfigurationHeader {
                runner.reset()
            }
            
            SpeedControlSection(
                renderEnabled: $runner.renderEnabled,
                targetFPS: $runner.targetFPS,
                turboMode: $runner.turboMode,
                isTraining: runner.isTraining,
                onRenderChange: {
                    runner.stopTraining()
                    runner.setupEnvironment()
                }
            )
            
            TrainingLimitsSection(
                episodesPerRun: $runner.episodesPerRun,
                maxStepsPerEpisode: $runner.maxStepsPerEpisode,
                isTraining: runner.isTraining,
                episodesRange: 10...5000
            )
            
            DQNHyperparametersSection(
                learningRate: $runner.learningRate,
                learningRateRange: 0.0001...0.1,
                gamma: $runner.gamma,
                epsilon: $runner.epsilon,
                epsilonDecaySteps: $runner.epsilonDecaySteps,
                epsilonMin: $runner.epsilonMin,
                targetUpdateFrequency: $runner.targetUpdateFrequency,
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining,
                warmupSteps: $runner.warmupSteps,
                showWarmup: true
            )
            
            environmentSection
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }
    
    private var environmentSection: some View {
        DisclosureGroup("Environment") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Goal Velocity")
                    Spacer()
                    TextField("0.0", value: $runner.goalVelocity, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                Text("Velocity threshold at goal position (default: 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .onChange(of: runner.goalVelocity) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
        }
        .disabled(runner.isTraining)
    }
}

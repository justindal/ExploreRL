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
                tau: $runner.tau,
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining,
                warmupSteps: $runner.warmupSteps,
                showWarmup: true
            )
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment Info")
                    .font(.headline)
                
                EnvironmentInfoRow(label: "State Space", value: "Box(2,)")
                EnvironmentInfoRow(label: "Observation", value: "[position, velocity]")
                EnvironmentInfoRow(label: "Position Range", value: "[-1.2, 0.6]")
                EnvironmentInfoRow(label: "Velocity Range", value: "[-0.07, 0.07]")
                EnvironmentInfoRow(label: "Action Space", value: "Discrete(3)")
                EnvironmentInfoRow(label: "Actions", value: "Left (0), None (1), Right (2)")
                EnvironmentInfoRow(label: "Reward", value: "-1 per step")
                EnvironmentInfoRow(label: "Goal Position", value: "≥ 0.5")
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }
}

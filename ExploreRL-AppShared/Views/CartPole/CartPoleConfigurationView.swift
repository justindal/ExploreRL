//
//  CartPoleConfigurationView.swift
//

import SwiftUI

struct CartPoleConfigurationView: View {
    @Bindable var runner: CartPoleRunner
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ConfigurationHeader {
                runner.resetToDefaults()
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
                isTraining: runner.isTraining
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
                isTraining: runner.isTraining
            )
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment Info")
                    .font(.headline)
                
                EnvironmentInfoRow(label: "State Space", value: "Box(4,)")
                EnvironmentInfoRow(label: "Observation", value: "[x, ẋ, θ, θ̇]")
                EnvironmentInfoRow(label: "Action Space", value: "Discrete(2)")
                EnvironmentInfoRow(label: "Actions", value: "Left (0), Right (1)")
                EnvironmentInfoRow(label: "Reward", value: "+1 per step alive")
                EnvironmentInfoRow(label: "Termination", value: "|θ| > 12° or |x| > 2.4")
                EnvironmentInfoRow(label: "Max Steps", value: "500 (CartPole-v1)")
            }
            
            DQNAdvancedSection(
                useSeed: $runner.useSeed,
                seed: $runner.seed,
                earlyStopEnabled: $runner.earlyStopEnabled,
                earlyStopWindow: $runner.earlyStopWindow,
                earlyStopRewardThreshold: $runner.earlyStopRewardThreshold,
                clipReward: $runner.clipReward,
                clipRewardMin: $runner.clipRewardMin,
                clipRewardMax: $runner.clipRewardMax,
                gradClipNorm: $runner.gradClipNorm,
                isTraining: runner.isTraining
            )
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

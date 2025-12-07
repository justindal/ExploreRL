//
//  AcrobotConfigurationView.swift
//

import SwiftUI

struct AcrobotConfigurationView: View {
    @Bindable var runner: AcrobotRunner
    
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
                isTraining: runner.isTraining,
                stepsRange: 100...1000,
                stepsStep: 50
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
                
                EnvironmentInfoRow(label: "State Space", value: "Box(6,)")
                EnvironmentInfoRow(label: "Observation", value: "[cos(θ₁), sin(θ₁), cos(θ₂), sin(θ₂), θ̇₁, θ̇₂]")
                EnvironmentInfoRow(label: "Action Space", value: "Discrete(3)")
                EnvironmentInfoRow(label: "Actions", value: "-1, 0, +1 torque")
                EnvironmentInfoRow(label: "Reward", value: "-1 per step, 0 on success")
                EnvironmentInfoRow(label: "Termination", value: "Tip above target height")
                EnvironmentInfoRow(label: "Max Steps", value: "500 (Acrobot-v1)")
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

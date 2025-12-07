//
//  MountainCarContinuousConfigurationView.swift
//

import SwiftUI

struct MountainCarContinuousConfigurationView: View {
    @Bindable var runner: MountainCarContinuousRunner
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ConfigurationHeader {
                runner.reset()
            }
            
            SpeedControlSection(
                renderEnabled: $runner.renderEnabled,
                targetFPS: $runner.targetFPS,
                turboMode: .constant(false),
                isTraining: runner.isTraining,
                showTurboMode: false,
                onRenderChange: {
                    runner.stopTraining()
                    runner.setupEnvironment()
                }
            )
            
            TrainingLimitsSection(
                episodesPerRun: $runner.episodesPerRun,
                maxStepsPerEpisode: $runner.maxStepsPerEpisode,
                isTraining: runner.isTraining,
                stepsRange: 100...2000,
                stepsStep: 100
            )
            
            SACHyperparametersSection(
                learningRate: $runner.learningRate,
                learningRateRange: 0.0001...0.01,
                gamma: $runner.gamma,
                tau: $runner.tau,
                tauRange: 0.001...0.05,
                alpha: $runner.alpha,
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining
            )
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment Info")
                    .font(.headline)
                
                EnvironmentInfoRow(label: "State Space", value: "Box(2,)")
                EnvironmentInfoRow(label: "Observation", value: "[position, velocity]")
                EnvironmentInfoRow(label: "Position Range", value: "[-1.2, 0.6]")
                EnvironmentInfoRow(label: "Velocity Range", value: "[-0.07, 0.07]")
                EnvironmentInfoRow(label: "Action Space", value: "Box(1,) [-1, 1]")
                EnvironmentInfoRow(label: "Reward", value: "100 at goal - action²×0.1")
                EnvironmentInfoRow(label: "Goal Position", value: "≥ 0.45")
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

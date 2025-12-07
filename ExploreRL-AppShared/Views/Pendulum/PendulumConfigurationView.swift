//
//  PendulumConfigurationView.swift
//

import SwiftUI

struct PendulumConfigurationView: View {
    @Bindable var runner: PendulumRunner
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ConfigurationHeader(resetLabel: "Reset") {
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
                stepsRange: 50...500,
                stepsStep: 50
            )
            
            SACHyperparametersSection(
                learningRate: $runner.learningRate,
                learningRateRange: 0.00001...0.01,
                gamma: $runner.gamma,
                tau: $runner.tau,
                tauRange: 0.001...0.1,
                alpha: $runner.alpha,
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining,
                warmupSteps: $runner.warmupSteps,
                showWarmup: true
            )
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment Info")
                    .font(.headline)
                
                EnvironmentInfoRow(label: "State Space", value: "Box(3,)")
                EnvironmentInfoRow(label: "Observation", value: "[cos(θ), sin(θ), θ̇]")
                EnvironmentInfoRow(label: "Action Space", value: "Box(1,)")
                EnvironmentInfoRow(label: "Action Range", value: "[-2.0, 2.0] torque")
                EnvironmentInfoRow(label: "Reward", value: "-(θ² + 0.1θ̇² + 0.001τ²)")
                EnvironmentInfoRow(label: "Goal", value: "Balance pendulum upright")
                EnvironmentInfoRow(label: "Max Steps", value: "200 (Pendulum-v1)")
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

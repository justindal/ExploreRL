//
//  LunarLanderContinuousConfigurationView.swift
//

import SwiftUI

struct LunarLanderContinuousConfigurationView: View {
    @Bindable var runner: LunarLanderContinuousRunner
    
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
                stepsRange: 100...2000,
                stepsStep: 100
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
                showWarmup: true,
                bufferSize: $runner.bufferSize,
                showBuffer: true
            )
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment Info")
                    .font(.headline)
                
                EnvironmentInfoRow(label: "State Space", value: "Box(8,)")
                EnvironmentInfoRow(label: "Observation", value: "[x, y, vx, vy, θ, ω, leg_l, leg_r]")
                EnvironmentInfoRow(label: "Action Space", value: "Box(2,)")
                EnvironmentInfoRow(label: "Actions", value: "[main_engine, lateral]")
                EnvironmentInfoRow(label: "Reward", value: "~100-140 for landing")
                EnvironmentInfoRow(label: "Termination", value: "Crash or successful land")
            }
            
            SeedSection(
                useSeed: $runner.useSeed,
                seed: $runner.seed,
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

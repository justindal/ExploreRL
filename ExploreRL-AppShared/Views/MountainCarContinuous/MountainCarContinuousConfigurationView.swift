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
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining
            )
            
            explorationSection
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
    
    private var explorationSection: some View {
        DisclosureGroup("Exploration") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Use SDE", isOn: $runner.useSDE)
                    .onChange(of: runner.useSDE) { _, _ in
                        runner.stopTraining()
                        runner.setupEnvironment()
                    }
                
                Text("When disabled, the policy uses a fixed standard deviation for exploration.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .disabled(runner.isTraining)
    }
}

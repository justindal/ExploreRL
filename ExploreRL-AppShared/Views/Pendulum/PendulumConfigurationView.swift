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
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining,
                warmupSteps: $runner.warmupSteps,
                showWarmup: true
            )
            
            SACEntropySection(
                autoAlpha: $runner.autoAlpha,
                initAlpha: $runner.initAlpha,
                alphaLr: $runner.alphaLr,
                alpha: $runner.alpha,
                trainFreqSteps: $runner.trainFreqSteps,
                gradientStepsPerTrain: $runner.gradientStepsPerTrain,
                isTraining: runner.isTraining
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
                    Text("Gravity (g)")
                    Spacer()
                    TextField("10.0", value: $runner.gravity, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                Text("Gravitational acceleration (default: 10.0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .onChange(of: runner.gravity) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
        }
        .disabled(runner.isTraining)
    }
}

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
                isTraining: runner.isTraining,
                warmupSteps: $runner.warmupSteps,
                showWarmup: true,
                bufferSize: $runner.bufferSize,
                showBuffer: true
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
            
            networkSection
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
                Toggle("Use gSDE", isOn: $runner.useGSDE)
                    .onChange(of: runner.useGSDE) { _, _ in
                        runner.stopTraining()
                        runner.setupEnvironment()
                    }
                
                if runner.useGSDE {
                    HStack {
                        Text("SDE Sample Freq")
                        Spacer()
                        TextField("-1", value: $runner.sdeSampleFreq, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    Text("Resample the gSDE exploration matrix. Use -1 to resample once per episode; use N>0 to resample every N steps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Toggle("Learned Std", isOn: $runner.learnedStd)
                        .onChange(of: runner.learnedStd) { _, _ in
                            runner.stopTraining()
                            runner.setupEnvironment()
                        }
                    
                    Text("When enabled, the policy learns a state-dependent standard deviation. When disabled, uses a fixed std for exploration.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .disabled(runner.isTraining)
    }
    
    private var networkSection: some View {
        DisclosureGroup("Network") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Hidden Size", selection: $runner.hiddenSize) {
                    Text("64").tag(64)
                    Text("128").tag(128)
                    Text("256").tag(256)
                }
                .pickerStyle(.segmented)
                .onChange(of: runner.hiddenSize) { _, _ in
                    runner.stopTraining()
                    runner.setupEnvironment()
                }
            }
            .padding(.top, 8)
        }
        .disabled(runner.isTraining)
    }
}

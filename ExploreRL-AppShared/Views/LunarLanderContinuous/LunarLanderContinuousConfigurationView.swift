//
//  LunarLanderContinuousConfigurationView.swift
//

import SwiftUI

struct LunarLanderContinuousConfigurationView: View {
    @Bindable var runner: LunarLanderContinuousRunner
    
    @State private var showLearningRateInfo = false
    @State private var showGammaInfo = false
    @State private var showAlphaInfo = false
    @State private var showTauInfo = false
    @State private var showBatchSizeInfo = false
    @State private var showBufferSizeInfo = false
    @State private var showWarmupInfo = false
    @State private var showSeedInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Configuration")
                    .font(.title3)
                    .bold()
                Spacer()
                Button("Reset to Defaults") {
                    runner.resetToDefaults()
                    runner.reset()
                }
                .font(.caption)
                .buttonStyle(.bordered)
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
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Hyperparameters (SAC)")
                    .font(.headline)
                
                let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 12) {
                    Group {
                        let lrBinding = doubleBinding(for: $runner.learningRate, range: 0.00001...0.01, step: 0.00001)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Learning Rate").lineLimit(1).minimumScaleFactor(0.9)
                                InfoButton(isPresented: $showLearningRateInfo, title: "Learning Rate", description: "Step size for network weight updates.", icon: "bolt.horizontal")
                                Spacer()
                                DoubleInputField(value: lrBinding, decimals: 5).disabled(runner.isTraining)
                            }
                            Slider(value: lrBinding, in: 0.00001...0.01).disabled(runner.isTraining)
                        }
                        
                        let gammaBinding = doubleBinding(for: $runner.gamma, range: 0.9...0.999, step: 0.001)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Gamma (Discount)").lineLimit(1).minimumScaleFactor(0.9)
                                InfoButton(isPresented: $showGammaInfo, title: "Gamma", description: "Discount factor for future rewards.", icon: "clock.arrow.circlepath")
                                Spacer()
                                DoubleInputField(value: gammaBinding, decimals: 3).disabled(runner.isTraining)
                            }
                            Slider(value: gammaBinding, in: 0.9...0.999).disabled(runner.isTraining)
                        }
                        
                        let alphaBinding = doubleBinding(for: $runner.alpha, range: 0.01...1.0, step: 0.01)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Alpha (Entropy)").lineLimit(1).minimumScaleFactor(0.9)
                                InfoButton(isPresented: $showAlphaInfo, title: "Alpha", description: "Entropy regularization coefficient for exploration.", icon: "waveform.path.ecg")
                                Spacer()
                                DoubleInputField(value: alphaBinding, decimals: 2).disabled(runner.isTraining)
                            }
                            Slider(value: alphaBinding, in: 0.01...1.0).disabled(runner.isTraining)
                        }
                        
                        let tauBinding = doubleBinding(for: $runner.tau, range: 0.001...0.1, step: 0.001)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Tau (Soft Update)").lineLimit(1).minimumScaleFactor(0.9)
                                InfoButton(isPresented: $showTauInfo, title: "Tau", description: "Soft update coefficient for target networks.", icon: "arrow.triangle.2.circlepath")
                                Spacer()
                                DoubleInputField(value: tauBinding, decimals: 3).disabled(runner.isTraining)
                            }
                            Slider(value: tauBinding, in: 0.001...0.1).disabled(runner.isTraining)
                        }
                    }
                    
                    Group {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Batch Size").lineLimit(1).minimumScaleFactor(0.9)
                                InfoButton(isPresented: $showBatchSizeInfo, title: "Batch Size", description: "Number of transitions sampled from replay buffer per update step.", icon: "info.circle")
                                Spacer()
                                Text("\(runner.batchSize)").monospacedDigit()
                            }
                            Picker("", selection: $runner.batchSize) {
                                Text("64").tag(64)
                                Text("128").tag(128)
                                Text("256").tag(256)
                                Text("512").tag(512)
                            }
                            .pickerStyle(.segmented)
                            .disabled(runner.isTraining)
                        }
                        
                        let minBuffer = 10_000.0
                        let maxBuffer = 1_000_000.0
                        let bufferBinding = Binding<Double>(
                            get: { Double(runner.bufferSize) },
                            set: {
                                let clamped = min(maxBuffer, max(minBuffer, $0.rounded()))
                                runner.bufferSize = Int(clamped)
                            }
                        )
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Buffer Size").lineLimit(1).minimumScaleFactor(0.9)
                                InfoButton(isPresented: $showBufferSizeInfo, title: "Buffer Size", description: "Replay buffer capacity.", icon: "memorychip")
                                Spacer()
                                DoubleInputField(value: bufferBinding, decimals: 0).disabled(runner.isTraining)
                            }
                            Slider(value: bufferBinding, in: minBuffer...maxBuffer, step: 10_000).disabled(runner.isTraining)
                        }
                        
                        let minWarmup = 100.0
                        let maxWarmup = 50_000.0
                        let warmupBinding = Binding<Double>(
                            get: { Double(runner.warmupSteps) },
                            set: {
                                let clamped = min(maxWarmup, max(minWarmup, $0.rounded()))
                                runner.warmupSteps = Int(clamped)
                            }
                        )
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Warmup Steps").lineLimit(1).minimumScaleFactor(0.9)
                                InfoButton(isPresented: $showWarmupInfo, title: "Warmup Steps", description: "Random actions before training starts.", icon: "flame")
                                Spacer()
                                DoubleInputField(value: warmupBinding, decimals: 0).disabled(runner.isTraining)
                            }
                            Slider(value: warmupBinding, in: minWarmup...maxWarmup, step: 100).disabled(runner.isTraining)
                        }
                    }
                }
            }
            
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
            
            DisclosureGroup("Advanced") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Use Seed")
                            .lineLimit(1)
                        InfoButton(isPresented: $showSeedInfo, title: "Seed", description: "Enable deterministic initialization for reproducible runs.", icon: "info.circle")
                        Spacer()
                        Toggle("", isOn: $runner.useSeed)
                            .labelsHidden()
                            .fixedSize()
                            .disabled(runner.isTraining)
                    }
                    
                    if runner.useSeed {
                        let seedBinding = Binding<Double>(
                            get: { Double(runner.seed) },
                            set: { runner.seed = Int($0.rounded()) }
                        )
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Seed Value")
                                Spacer()
                                DoubleInputField(value: seedBinding, decimals: 0)
                                    .disabled(runner.isTraining)
                            }
                            Slider(value: seedBinding, in: 0...1000, step: 1)
                                .disabled(runner.isTraining)
                        }
                    }
                }
                .padding(.top, 8)
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
    
    private func doubleBinding(for floatBinding: Binding<Double>, range: ClosedRange<Double>, step: Double? = nil) -> Binding<Double> {
        Binding<Double>(
            get: { floatBinding.wrappedValue },
            set: {
                var newValue = $0
                if let step = step {
                    newValue = (newValue / step).rounded() * step
                }
                floatBinding.wrappedValue = min(max(newValue, range.lowerBound), range.upperBound)
            }
        )
    }
}

private struct EnvironmentInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

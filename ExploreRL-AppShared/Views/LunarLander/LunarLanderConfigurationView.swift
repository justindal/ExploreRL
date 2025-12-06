//
//  LunarLanderConfigurationView.swift
//

import SwiftUI

struct LunarLanderConfigurationView: View {
    @Bindable var runner: LunarLanderRunner
    
    @State private var showLearningRateInfo = false
    @State private var showGammaInfo = false
    @State private var showEpsilonInfo = false
    @State private var showDecayInfo = false
    @State private var showTauInfo = false
    @State private var showBatchSizeInfo = false
    @State private var showEpsilonMinInfo = false
    @State private var showSeedInfo = false
    @State private var showEarlyStopInfo = false
    @State private var showClipInfo = false
    @State private var showGradClipInfo = false
    
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
                Text("Hyperparameters (DQN)")
                    .font(.headline)
                
                let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 12) {
                    Group {
                        let lrBinding = doubleBinding(for: $runner.learningRate, range: 0.00001...0.01, step: 0.00001)
                        VStack(alignment: .leading) {
                            HStack { Text("Learning Rate").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showLearningRateInfo, title: "Learning Rate", description: "Step size for network weight updates.", icon: "bolt.horizontal"); Spacer(); DoubleInputField(value: lrBinding, decimals: 5).disabled(runner.isTraining) }
                            Slider(value: lrBinding, in: 0.00001...0.01).disabled(runner.isTraining)
                        }
                        
                        let gammaBinding = doubleBinding(for: $runner.gamma, range: 0.9...0.999, step: 0.001)
                        VStack(alignment: .leading) {
                            HStack { Text("Gamma (Discount)").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showGammaInfo, title: "Gamma", description: "Discount factor for future rewards.", icon: "clock.arrow.circlepath"); Spacer(); DoubleInputField(value: gammaBinding, decimals: 3).disabled(runner.isTraining) }
                            Slider(value: gammaBinding, in: 0.9...0.999).disabled(runner.isTraining)
                        }
                        
                        let epsilonBinding = doubleBinding(for: $runner.epsilon, range: 0.0...1.0, step: 0.01)
                        VStack(alignment: .leading) {
                            HStack { Text("Epsilon (Exploration)").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showEpsilonInfo, title: "Epsilon", description: "Probability of random action.", icon: "die.face.5"); Spacer(); DoubleInputField(value: epsilonBinding, decimals: 2).disabled(runner.isTraining) }
                            Slider(value: epsilonBinding, in: 0.0...1.0).disabled(runner.isTraining)
                        }
                        
                        let minDecaySteps = 1_000.0
                        let maxDecaySteps = 200_000.0
                        let decayStepsBinding = Binding<Double>(
                            get: { Double(runner.epsilonDecaySteps) },
                            set: {
                                let clamped = min(
                                    maxDecaySteps,
                                    max(minDecaySteps, $0.rounded())
                                )
                                runner.epsilonDecaySteps = Int(clamped)
                            }
                        )
                        VStack(alignment: .leading) {
                            HStack { Text("Epsilon Decay Steps").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showDecayInfo, title: "Decay Schedule", description: "Time constant (in optimizer steps) for exponential epsilon decay.", icon: "arrow.down.right.circle"); Spacer(); DoubleInputField(value: decayStepsBinding, decimals: 0).disabled(runner.isTraining) }
                            Slider(value: decayStepsBinding, in: minDecaySteps...maxDecaySteps, step: 1_000).disabled(runner.isTraining)
                        }
                        
                        let epsMinBinding = doubleBinding(for: $runner.epsilonMin, range: 0.0...1.0, step: 0.001)
                        VStack(alignment: .leading) {
                            HStack { Text("Epsilon Min").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showEpsilonMinInfo, title: "Epsilon Min", description: "Lower bound for exploration probability.", icon: "info.circle"); Spacer(); DoubleInputField(value: epsMinBinding, decimals: 3).disabled(runner.isTraining) }
                            Slider(value: epsMinBinding, in: 0.0...1.0).disabled(runner.isTraining)
                        }
                    }
                    
                    Group {
                        let tauBinding = doubleBinding(for: $runner.tau, range: 0.001...0.1, step: 0.001)
                        VStack(alignment: .leading) {
                            HStack { Text("Tau (Soft Update)").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showTauInfo, title: "Tau", description: "Soft update coefficient.", icon: "arrow.triangle.2.circlepath"); Spacer(); DoubleInputField(value: tauBinding, decimals: 3).disabled(runner.isTraining) }
                            Slider(value: tauBinding, in: 0.001...0.1).disabled(runner.isTraining)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("Batch Size").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showBatchSizeInfo, title: "Batch Size", description: "Number of transitions sampled from replay buffer per update step.", icon: "info.circle"); Spacer(); Text("\(runner.batchSize)").monospacedDigit() }
                            Picker("", selection: $runner.batchSize) {
                                Text("32").tag(32)
                                Text("64").tag(64)
                                Text("128").tag(128)
                                Text("256").tag(256)
                            }
                            .pickerStyle(.segmented)
                            .disabled(runner.isTraining)
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
                EnvironmentInfoRow(label: "Action Space", value: "Discrete(4)")
                EnvironmentInfoRow(label: "Actions", value: "Noop, Left, Main, Right")
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
                    
                    Divider()
                    
                    HStack {
                        Text("Early Stop")
                            .lineLimit(1)
                        InfoButton(isPresented: $showEarlyStopInfo, title: "Early Stop", description: "Stop training when average reward exceeds threshold.", icon: "info.circle")
                        Spacer()
                        Toggle("", isOn: $runner.earlyStopEnabled)
                            .labelsHidden()
                            .fixedSize()
                            .disabled(runner.isTraining)
                    }
                    
                    if runner.earlyStopEnabled {
                        let thresholdBinding = doubleBinding(for: $runner.earlyStopRewardThreshold, range: 0...300, step: 10)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Reward Threshold")
                                Spacer()
                                DoubleInputField(value: thresholdBinding, decimals: 0)
                                    .disabled(runner.isTraining)
                            }
                            Slider(value: thresholdBinding, in: 0...300, step: 10)
                                .disabled(runner.isTraining)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Clip Reward")
                            .lineLimit(1)
                        InfoButton(isPresented: $showClipInfo, title: "Reward Clipping", description: "Clip rewards to a specified range.", icon: "info.circle")
                        Spacer()
                        Toggle("", isOn: $runner.clipReward)
                            .labelsHidden()
                            .fixedSize()
                            .disabled(runner.isTraining)
                    }
                    
                    if runner.clipReward {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Min")
                                    .font(.caption)
                                TextField("Min", value: $runner.clipRewardMin, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                    .disabled(runner.isTraining)
                            }
                            VStack(alignment: .leading) {
                                Text("Max")
                                    .font(.caption)
                                TextField("Max", value: $runner.clipRewardMax, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                    .disabled(runner.isTraining)
                            }
                        }
                    }
                    
                    Divider()
                    
                    let gradClipBinding = doubleBinding(for: $runner.gradClipNorm, range: 0.1...100, step: 0.1)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Gradient Clip Norm")
                                .lineLimit(1)
                            InfoButton(isPresented: $showGradClipInfo, title: "Gradient Clipping", description: "Maximum norm for gradient clipping to prevent exploding gradients.", icon: "info.circle")
                            Spacer()
                            DoubleInputField(value: gradClipBinding, decimals: 1)
                                .disabled(runner.isTraining)
                        }
                        Slider(value: gradClipBinding, in: 0.1...100)
                            .disabled(runner.isTraining)
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

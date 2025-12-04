//
//  AcrobotConfigurationView.swift
//

import SwiftUI

struct AcrobotConfigurationView: View {
    @Bindable var runner: AcrobotRunner
    
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
                stepsRange: 100...1000,
                stepsStep: 50
            )
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Hyperparameters (DQN)")
                    .font(.headline)
                
                let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 12) {
                    Group {
                        let lrBinding = doubleBinding(for: $runner.learningRate, range: 0.0001...0.1, step: 0.0001)
                        VStack(alignment: .leading) {
                            HStack { Text("Learning Rate").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showLearningRateInfo, title: "Learning Rate", description: "Step size for network weight updates.", icon: "bolt.horizontal"); Spacer(); DoubleInputField(value: lrBinding, decimals: 4).disabled(runner.isTraining) }
                            Slider(value: lrBinding, in: 0.0001...0.1).disabled(runner.isTraining)
                        }
                        
                        let gammaBinding = doubleBinding(for: $runner.gamma, range: 0.8...0.999, step: 0.001)
                        VStack(alignment: .leading) {
                            HStack { Text("Gamma (Discount)").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showGammaInfo, title: "Gamma", description: "Discount factor for future rewards.", icon: "clock.arrow.circlepath"); Spacer(); DoubleInputField(value: gammaBinding, decimals: 3).disabled(runner.isTraining) }
                            Slider(value: gammaBinding, in: 0.8...0.999).disabled(runner.isTraining)
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
                
                EnvironmentInfoRow(label: "State Space", value: "Box(6,)")
                EnvironmentInfoRow(label: "Observation", value: "[cos(θ₁), sin(θ₁), cos(θ₂), sin(θ₂), θ̇₁, θ̇₂]")
                EnvironmentInfoRow(label: "Action Space", value: "Discrete(3)")
                EnvironmentInfoRow(label: "Actions", value: "-1, 0, +1 torque")
                EnvironmentInfoRow(label: "Reward", value: "-1 per step, 0 on success")
                EnvironmentInfoRow(label: "Termination", value: "Tip above target height")
                EnvironmentInfoRow(label: "Max Steps", value: "500 (Acrobot-v1)")
            }
            
            DisclosureGroup("Advanced") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text("Use Seed"); InfoButton(isPresented: $showSeedInfo, title: "Seed", description: "Enable deterministic initialization for reproducible runs.", icon: "info.circle"); Spacer(); Toggle("", isOn: $runner.useSeed).labelsHidden().disabled(runner.isTraining) }
                    HStack {
                        Text("Seed")
                        Spacer()
                        TextField("0", value: $runner.seed, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                            .disabled(!runner.useSeed || runner.isTraining)
                    }
                    
                    HStack { Text("Early Stop on Average Reward"); InfoButton(isPresented: $showEarlyStopInfo, title: "Early Stop", description: "Automatically stop training when the moving average reward exceeds the threshold.", icon: "info.circle"); Spacer(); Toggle("", isOn: $runner.earlyStopEnabled).labelsHidden().disabled(runner.isTraining) }
                    HStack {
                        Text("Window (episodes)")
                        Spacer()
                        TextField("100", value: $runner.earlyStopWindow, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                            .disabled(!runner.earlyStopEnabled || runner.isTraining)
                    }
                    HStack {
                        Text("Threshold")
                        Spacer()
                        TextField("-100", value: $runner.earlyStopRewardThreshold, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                            .disabled(!runner.earlyStopEnabled || runner.isTraining)
                    }
                    
                    HStack { Text("Clip Reward"); InfoButton(isPresented: $showClipInfo, title: "Clip Reward", description: "Clamp rewards into a fixed range to improve stability.", icon: "info.circle"); Spacer(); Toggle("", isOn: $runner.clipReward).labelsHidden().disabled(runner.isTraining) }
                    HStack {
                        Text("Min")
                        Spacer()
                        TextField("-1.0", value: $runner.clipRewardMin, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                    }.disabled(!runner.clipReward || runner.isTraining)
                    HStack {
                        Text("Max")
                        Spacer()
                        TextField("1.0", value: $runner.clipRewardMax, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                    }.disabled(!runner.clipReward || runner.isTraining)
                    
                    let gradClipBinding = doubleBinding(for: $runner.gradClipNorm, range: 1...1000, step: 1)
                    VStack(alignment: .leading) {
                        HStack { Text("Grad Clip Norm").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showGradClipInfo, title: "Gradient Clipping", description: "Clamp the global gradient norm to this maximum to prevent exploding gradients.", icon: "info.circle"); Spacer(); DoubleInputField(value: gradClipBinding, decimals: 0).disabled(runner.isTraining) }
                        Slider(value: gradClipBinding, in: 1...1000).disabled(runner.isTraining)
                    }
                }
                .padding(.top, 6)
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

    private func clampedDoubleBinding(_ binding: Binding<Double>, range: ClosedRange<Double>, step: Double? = nil) -> Binding<Double> {
        Binding<Double>(
            get: { min(max(binding.wrappedValue, range.lowerBound), range.upperBound) },
            set: {
                var newValue = $0
                if let step = step {
                    newValue = (newValue / step).rounded() * step
                }
                binding.wrappedValue = min(max(newValue, range.lowerBound), range.upperBound)
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
                .font(.system(.body, design: .monospaced))
        }
        .font(.caption)
    }
}


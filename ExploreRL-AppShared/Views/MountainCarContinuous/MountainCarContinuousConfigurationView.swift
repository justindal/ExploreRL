//
//  MountainCarContinuousConfigurationView.swift
//

import SwiftUI

struct MountainCarContinuousConfigurationView: View {
    @Bindable var runner: MountainCarContinuousRunner
    
    @State private var showLearningRateInfo = false
    @State private var showGammaInfo = false
    @State private var showTauInfo = false
    @State private var showAlphaInfo = false
    @State private var showBatchSizeInfo = false
    
    @State private var showRenderConfirm = false
    @State private var proposedRenderEnabled = true
    
    private var renderSegment: Binding<Int> {
        Binding(
            get: { runner.renderEnabled ? 1 : 0 },
            set: { newVal in
                let newEnabled = (newVal == 1)
                guard newEnabled != runner.renderEnabled else { return }
                
                if runner.isTraining {
                    proposedRenderEnabled = newEnabled
                    showRenderConfirm = true
                } else {
                    runner.stopTraining()
                    runner.renderEnabled = newEnabled
                    runner.setupEnvironment()
                }
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Configuration")
                    .font(.title3)
                    .bold()
                Spacer()
                Button("Reset to Defaults") {
                    runner.reset()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            
            VStack(alignment: .leading) {
                Text("Speed & Run Control")
                    .font(.headline)
                Picker("Render", selection: renderSegment) {
                    Text("Off").tag(0)
                    Text("On").tag(1)
                }
                .pickerStyle(.segmented)
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Switching render mode resets the environment.")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                
                if runner.renderEnabled {
                    let fpsBinding = clampedDoubleBinding($runner.targetFPS, range: 1...120, step: 1)
                    HStack {
                        Text("Target FPS")
                        Spacer()
                        DoubleInputField(value: fpsBinding, decimals: 0, width: 70)
                    }
                    Slider(value: fpsBinding, in: 1...120)
                }
                
                let episodesBinding = Binding<Double>(
                    get: { Double(runner.episodesPerRun) },
                    set: { runner.episodesPerRun = max(1, Int($0.rounded())) }
                )
                HStack {
                    Text("Episodes Per Run")
                    Spacer()
                    TextField("500", value: $runner.episodesPerRun, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .disabled(runner.isTraining)
                }
                Slider(value: episodesBinding, in: 10...2000)
                    .disabled(runner.isTraining)
                
                let maxStepsBinding = Binding<Double>(
                    get: { Double(runner.maxStepsPerEpisode) },
                    set: { runner.maxStepsPerEpisode = Int($0) }
                )
                HStack {
                    Text("Max Steps / Episode")
                    Spacer()
                    Text("\(runner.maxStepsPerEpisode)")
                        .monospacedDigit()
                }
                Slider(value: maxStepsBinding, in: 100...2000, step: 100)
                    .disabled(runner.isTraining)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Hyperparameters (SAC)")
                    .font(.headline)
                
                let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 12) {
                    let lrBinding = doubleBinding(for: $runner.learningRate, range: 0.0001...0.01, step: 0.0001)
                    VStack(alignment: .leading) {
                        HStack { Text("Learning Rate").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showLearningRateInfo, title: "Learning Rate", description: "Step size for network weight updates.", icon: "bolt.horizontal"); Spacer(); DoubleInputField(value: lrBinding, decimals: 4).disabled(runner.isTraining) }
                        Slider(value: lrBinding, in: 0.0001...0.01).disabled(runner.isTraining)
                    }
                    
                    let gammaBinding = doubleBinding(for: $runner.gamma, range: 0.9...0.999, step: 0.001)
                    VStack(alignment: .leading) {
                        HStack { Text("Gamma (Discount)").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showGammaInfo, title: "Gamma", description: "Discount factor for future rewards.", icon: "clock.arrow.circlepath"); Spacer(); DoubleInputField(value: gammaBinding, decimals: 3).disabled(runner.isTraining) }
                        Slider(value: gammaBinding, in: 0.9...0.999).disabled(runner.isTraining)
                    }
                    
                    let tauBinding = doubleBinding(for: $runner.tau, range: 0.001...0.05, step: 0.001)
                    VStack(alignment: .leading) {
                        HStack { Text("Tau (Soft Update)").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showTauInfo, title: "Tau", description: "Soft update coefficient for target networks.", icon: "arrow.triangle.2.circlepath"); Spacer(); DoubleInputField(value: tauBinding, decimals: 3).disabled(runner.isTraining) }
                        Slider(value: tauBinding, in: 0.001...0.05).disabled(runner.isTraining)
                    }
                    
                    let alphaBinding = doubleBinding(for: $runner.alpha, range: 0.01...1.0, step: 0.01)
                    VStack(alignment: .leading) {
                        HStack { Text("Alpha (Entropy)").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showAlphaInfo, title: "Alpha", description: "Entropy regularization coefficient (auto-tuned).", icon: "waveform"); Spacer(); DoubleInputField(value: alphaBinding, decimals: 2).disabled(runner.isTraining) }
                        Slider(value: alphaBinding, in: 0.01...1.0).disabled(runner.isTraining)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text("Batch Size").lineLimit(1).minimumScaleFactor(0.9); InfoButton(isPresented: $showBatchSizeInfo, title: "Batch Size", description: "Number of transitions sampled per update.", icon: "info.circle"); Spacer(); Text("\(runner.batchSize)").monospacedDigit() }
                        Picker("", selection: $runner.batchSize) {
                            Text("64").tag(64)
                            Text("128").tag(128)
                            Text("256").tag(256)
                            Text("512").tag(512)
                        }
                        .pickerStyle(.segmented)
                        .disabled(runner.isTraining)
                    }
                }
            }
            
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
        .alert("Switch render mode?", isPresented: $showRenderConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Switch", role: .destructive) {
                runner.stopTraining()
                runner.renderEnabled = proposedRenderEnabled
                runner.setupEnvironment()
            }
        } message: {
            Text("This will reset the environment and stop the current run.")
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }
    
    private func doubleBinding(for binding: Binding<Double>, range: ClosedRange<Double>, step: Double? = nil) -> Binding<Double> {
        Binding<Double>(
            get: { binding.wrappedValue },
            set: {
                var newValue = $0
                if let step = step {
                    newValue = (newValue / step).rounded() * step
                }
                binding.wrappedValue = min(max(newValue, range.lowerBound), range.upperBound)
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


//
//  FrozenLakeConfigurationView.swift
//

import SwiftUI

struct FrozenLakeConfigurationView: View {
    @Bindable var runner: FrozenLakeRunner
    
    @State private var showLearningRateInfo = false
    @State private var showGammaInfo = false
    @State private var showEpsilonInfo = false
    @State private var showDecayInfo = false
    
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
            
            VStack(alignment: .leading) {
                Text("Algorithm")
                    .font(.headline)
                
                Picker("Algorithm", selection: $runner.selectedAlgorithm) {
                    ForEach(RLAlgorithm.allCases) { algo in
                        Text(algo.rawValue).tag(algo)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(runner.selectedAlgorithm.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .disabled(runner.isTraining)
            
            VStack(alignment: .leading) {
                Text("Speed Control")
                    .font(.headline)
                Toggle("Turbo Mode", isOn: $runner.turboMode)
                if !runner.turboMode {
                    let fpsBinding = clampedDoubleBinding($runner.targetFPS, range: 1...120, step: 1)
                    HStack {
                        Text("Target FPS")
                        Spacer()
                        DoubleInputField(value: fpsBinding, decimals: 0, width: 70)
                    }
                    Slider(value: fpsBinding, in: 1...120)
                }
            }
            
            Group {
                VStack(alignment: .leading) {
                    Text("Environment")
                        .font(.headline)
                    
                    Toggle("Show Policy Arrows", isOn: $runner.showPolicy)
                    
                    Picker("Map Size", selection: $runner.mapName) {
                        Text("4x4").tag("4x4")
                        Text("8x8").tag("8x8")
                        Text("Custom").tag("Custom")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: runner.mapName) { _, _ in
                        runner.reset()
                    }
                    
                    if runner.mapName == "Custom" {
                        let mapBinding = clampedIntBinding($runner.customMapSize, range: 4...20)
                        HStack(spacing: 12) {
                            Text("Size")
                            Spacer()
                            IntInputField(value: mapBinding, width: 70)
                            Stepper("", value: mapBinding, in: 4...20)
                                .labelsHidden()
                        }
                        .onChange(of: runner.customMapSize) { _, _ in
                            runner.reset()
                        }
                        Text("(range 4-20)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Toggle("Slippery", isOn: $runner.isSlippery)
                        .onChange(of: runner.isSlippery) { _, _ in
                            runner.reset()
                        }
                }
                
                VStack(alignment: .leading) {
                    Text("Hyperparameters")
                        .font(.headline)
                    
                    let lrBinding = doubleBinding(for: $runner.learningRate, range: 0.01...1.0, step: 0.01)
                    HStack {
                        Text("Learning Rate")
                        InfoButton(isPresented: $showLearningRateInfo, title: "Learning Rate", description: "Controls how much the agent updates its knowledge based on new information. High values mean faster learning but can be unstable.", icon: "bolt.horizontal")
                        Spacer()
                        DoubleInputField(value: lrBinding, decimals: 3)
                    }
                    Slider(value: lrBinding, in: 0.01...1.0)
                    
                    let gammaBinding = doubleBinding(for: $runner.gamma, range: 0.8...0.999, step: 0.001)
                    HStack {
                        Text("Gamma (Discount)")
                        InfoButton(isPresented: $showGammaInfo, title: "Gamma (Discount)", description: "Determines the importance of future rewards. A value near 0 considers only immediate rewards, while a value near 1 strives for long-term high reward.", icon: "clock.arrow.circlepath")
                        Spacer()
                        DoubleInputField(value: gammaBinding, decimals: 3)
                    }
                    Slider(value: gammaBinding, in: 0.8...0.999)
                    
                    let epsilonBinding = doubleBinding(for: $runner.epsilon, range: 0.0...1.0, step: 0.01)
                    HStack {
                        Text("Epsilon (Exploration)")
                        InfoButton(isPresented: $showEpsilonInfo, title: "Epsilon (Exploration)", description: "The probability that the agent will explore a random action rather than exploiting its current knowledge.", icon: "die.face.5")
                        Spacer()
                        DoubleInputField(value: epsilonBinding, decimals: 2)
                    }
                    Slider(value: epsilonBinding, in: 0.0...1.0)
                    
                    let decayBinding = doubleBinding(for: $runner.epsilonDecay, range: 0.9...0.9999, step: 0.0001)
                    HStack {
                        Text("Epsilon Decay")
                        InfoButton(isPresented: $showDecayInfo, title: "Epsilon Decay", description: "Multiplies epsilon by this value after every episode. Allows high exploration early on and exploitation later.", icon: "arrow.down.right.circle")
                        Spacer()
                        DoubleInputField(value: decayBinding, decimals: 4)
                    }
                    Slider(value: decayBinding, in: 0.9...0.9999)
                }
                
                VStack(alignment: .leading) {
                    Text("Training Limits")
                        .font(.headline)
                    
                    let episodeBinding = clampedIntBinding($runner.episodesPerRun, range: 100...10000)
                    HStack(spacing: 12) {
                        Text("Episodes per Run")
                        Spacer()
                        IntInputField(value: episodeBinding, width: 90)
                        Stepper("", value: episodeBinding, in: 100...10000, step: 100)
                            .labelsHidden()
                    }
                    
                    let stepBinding = clampedIntBinding($runner.maxStepsPerEpisode, range: 10...1000)
                    HStack(spacing: 12) {
                        Text("Max Steps per Episode")
                        Spacer()
                        IntInputField(value: stepBinding, width: 90)
                        Stepper("", value: stepBinding, in: 10...1000, step: 10)
                            .labelsHidden()
                    }
                }
            }
            .disabled(runner.isTraining)
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }
    
    private func doubleBinding(for floatBinding: Binding<Float>, range: ClosedRange<Double>, step: Double? = nil) -> Binding<Double> {
        Binding<Double>(
            get: { Double(floatBinding.wrappedValue) },
            set: {
                var newValue = $0
                if let step = step {
                    newValue = (newValue / step).rounded() * step
                }
                floatBinding.wrappedValue = Float(min(max(newValue, range.lowerBound), range.upperBound))
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

    private func clampedIntBinding(_ binding: Binding<Int>, range: ClosedRange<Int>) -> Binding<Int> {
        Binding<Int>(
            get: { min(max(binding.wrappedValue, range.lowerBound), range.upperBound) },
            set: { binding.wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}


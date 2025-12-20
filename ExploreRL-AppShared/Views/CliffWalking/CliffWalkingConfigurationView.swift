//
//  CliffWalkingConfigurationView.swift
//

import SwiftUI

struct CliffWalkingConfigurationView: View {
    @Bindable var runner: CliffWalkingRunner
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ConfigurationHeader {
                runner.resetToDefaults()
                runner.reset()
            }
            
            algorithmSection
            
            SpeedControlSection(
                renderEnabled: $runner.renderEnabled,
                targetFPS: $runner.targetFPS,
                turboMode: $runner.turboMode,
                isTraining: runner.isTraining,
                onRenderChange: {
                    runner.stopTraining()
                    runner.reset()
                }
            )
            
            environmentSection
            
            hyperparametersSection
            
            TrainingLimitsSection(
                episodesPerRun: $runner.episodesPerRun,
                maxStepsPerEpisode: $runner.maxStepsPerEpisode,
                isTraining: runner.isTraining,
                episodesRange: 100...100000,
                stepsRange: 50...500
            )
            
            advancedSection
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }
    
    private var algorithmSection: some View {
        VStack(alignment: .leading) {
            Text("Algorithm")
                .font(.headline)
            
            Picker("Algorithm", selection: $runner.selectedAlgorithm) {
                ForEach(TabularAlgorithm.allCases) { algo in
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
    }
    
    private var environmentSection: some View {
        VStack(alignment: .leading) {
            Text("Environment")
                .font(.headline)
            
            Toggle("Slippery Surface", isOn: $runner.isSlippery)
                .onChange(of: runner.isSlippery) { _, _ in
                    guard !runner.isLoadingAgent else { return }
                    runner.reset()
                }
            
            Text("1/3 probability each for intended direction, left, or right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .disabled(runner.isTraining)
    }
    
    @State private var showLearningRateInfo = false
    @State private var showGammaInfo = false
    @State private var showEpsilonInfo = false
    @State private var showDecayInfo = false
    
    private var hyperparametersSection: some View {
        VStack(alignment: .leading) {
            Text("Hyperparameters")
                .font(.headline)
            
            let lrBinding = clampedBinding(for: $runner.learningRate, range: 0.01...1.0, step: 0.01)
            HStack {
                Text("Learning Rate")
                InfoButton(isPresented: $showLearningRateInfo, title: "Learning Rate", description: "Controls how much the agent updates its knowledge based on new information.", icon: "bolt.horizontal")
                Spacer()
                DoubleInputField(value: lrBinding, decimals: 3)
            }
            Slider(value: lrBinding, in: 0.01...1.0)
            
            let gammaBinding = clampedBinding(for: $runner.gamma, range: 0.8...0.999, step: 0.001)
            HStack {
                Text("Gamma (Discount)")
                InfoButton(isPresented: $showGammaInfo, title: "Gamma (Discount)", description: "Determines the importance of future rewards.", icon: "clock.arrow.circlepath")
                Spacer()
                DoubleInputField(value: gammaBinding, decimals: 3)
            }
            Slider(value: gammaBinding, in: 0.8...0.999)
            
            let epsilonBinding = clampedBinding(for: $runner.epsilon, range: 0.0...1.0, step: 0.01)
            HStack {
                Text("Epsilon (Exploration)")
                InfoButton(isPresented: $showEpsilonInfo, title: "Epsilon (Exploration)", description: "The probability of taking a random action.", icon: "die.face.5")
                Spacer()
                DoubleInputField(value: epsilonBinding, decimals: 2)
            }
            Slider(value: epsilonBinding, in: 0.0...1.0)
            
            let decayBinding = clampedBinding(for: $runner.epsilonDecay, range: 0.9...0.9999, step: 0.0001)
            HStack {
                Text("Epsilon Decay")
                InfoButton(isPresented: $showDecayInfo, title: "Epsilon Decay", description: "Multiplies epsilon by this value after every episode.", icon: "arrow.down.right.circle")
                Spacer()
                DoubleInputField(value: decayBinding, decimals: 4)
            }
            Slider(value: decayBinding, in: 0.9...0.9999)
        }
        .disabled(runner.isTraining)
    }
    
    private var advancedSection: some View {
        DisclosureGroup("Advanced") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Use Seed")
                    Spacer()
                    Toggle("", isOn: $runner.useSeed)
                        .labelsHidden()
                }
                .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("Seed")
                    Spacer()
                    TextField("0", value: $runner.seed, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .disabled(!runner.useSeed)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
        }
        .disabled(runner.isTraining)
    }
}


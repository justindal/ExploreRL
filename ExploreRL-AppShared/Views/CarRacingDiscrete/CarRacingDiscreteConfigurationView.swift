import SwiftUI

struct CarRacingDiscreteConfigurationView: View {
    @Bindable var runner: CarRacingDiscreteRunner
    
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
            
            DQNHyperparametersSection(
                learningRate: $runner.learningRate,
                learningRateRange: 0.00001...0.01,
                gamma: $runner.gamma,
                epsilon: $runner.epsilon,
                epsilonDecaySteps: $runner.epsilonDecaySteps,
                epsilonMin: $runner.epsilonMin,
                targetUpdateFrequency: $runner.targetUpdateFrequency,
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining,
                warmupSteps: $runner.warmupSteps,
                showWarmup: true
            )
            
            DQNAdvancedSection(
                useSeed: $runner.useSeed,
                seed: $runner.seed,
                earlyStopEnabled: $runner.earlyStopEnabled,
                earlyStopWindow: $runner.earlyStopWindow,
                earlyStopRewardThreshold: $runner.earlyStopRewardThreshold,
                clipReward: $runner.clipReward,
                clipRewardMin: $runner.clipRewardMin,
                clipRewardMax: $runner.clipRewardMax,
                gradClipNorm: $runner.gradClipNorm,
                isTraining: runner.isTraining
            )
            
            frameStackSection
            
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
    
    private var frameStackSection: some View {
        DisclosureGroup("Frame Stack") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Frame Stack", isOn: $runner.useFrameStack)
                
                if runner.useFrameStack {
                    HStack {
                        Text("Stack Size")
                        Spacer()
                        Stepper("\(runner.frameStackSize)", value: $runner.frameStackSize, in: 2...8)
                            .frame(width: 100)
                    }
                    
                    Text("Observation size: \(runner.currentObservationSize) features")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("Frame stacking provides temporal information for motion perception.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .onChange(of: runner.useFrameStack) { _, _ in
                runner.stopTraining()
                runner.reset()
            }
            .onChange(of: runner.frameStackSize) { _, _ in
                runner.stopTraining()
                runner.reset()
            }
        }
        .disabled(runner.isTraining)
    }
    
    private var environmentSection: some View {
        DisclosureGroup("Environment") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Lap Complete %")
                    Spacer()
                    TextField("0.95", value: $runner.lapCompletePercent, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                Toggle("Domain Randomize", isOn: $runner.domainRandomize)
                
                Text("Domain randomize varies track colors for better generalization")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .onChange(of: runner.lapCompletePercent) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
            .onChange(of: runner.domainRandomize) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
        }
        .disabled(runner.isTraining)
    }
}


//
//  AcrobotConfigurationView.swift
//

import SwiftUI

struct AcrobotConfigurationView: View {
    @Bindable var runner: AcrobotRunner
    
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
                stepsRange: 100...1000,
                stepsStep: 50
            )
            
            DQNHyperparametersSection(
                learningRate: $runner.learningRate,
                learningRateRange: 0.0001...0.1,
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
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }
}

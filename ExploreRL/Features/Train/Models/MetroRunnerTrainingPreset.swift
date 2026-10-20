import Foundation

enum MetroRunnerTrainingPreset: String, CaseIterable, Identifiable {
    case baseline = "Supplied Baseline"
    case longerRollout = "Longer Rollout"
    case fineTuning = "Fine-Tuning"

    var id: Self { self }

    func applying(to original: TrainingConfig, currentStep: Int) -> TrainingConfig {
        var config = original
        config.totalTimesteps = min(1_000_000_000, min(1_000_000_000, max(0, currentStep)) + (self == .baseline ? 100_000 : 1_000_000))
        config.ppo.nSteps = self == .baseline ? 512 : 2048
        config.ppo.batchSize = 256
        config.ppo.nEpochs = 5
        config.ppo.gamma = 0.995
        config.ppo.gaeLambda = 0.95
        config.ppo.learningRateSchedule = "constant"
        config.ppo.warmupEnabled = false
        config.ppo.learningRate = self == .fineTuning ? 1e-4 : 3e-4
        config.ppo.entCoef = self == .fineTuning ? 0.005 : 0.01
        return config
    }
}

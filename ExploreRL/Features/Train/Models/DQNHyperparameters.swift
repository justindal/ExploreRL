//
//  DQNHyperparameters.swift
//  ExploreRL
//

import Foundation

struct DQNHyperparameters: Equatable, Codable {
    var learningRate: Float = 1e-4
    var learningRateSchedule: String = "constant"
    var learningRateFinal: Float = 0.0
    var learningRateDecayRate: Float = 0.99
    var learningRateMinValue: Float = 0.0
    var learningRateMilestones: String = "0.5,0.75"
    var learningRateGamma: Float = 0.1
    var warmupEnabled: Bool = false
    var warmupFraction: Double = 0.05
    var warmupInitialValue: Float = 0.0
    var bufferSize: Int = 1_000_000
    var batchSize: Int = 32
    var gamma: Double = 0.99
    var tau: Double = 1.0
    var explorationFraction: Double = 0.2
    var explorationInitialEps: Double = 1.0
    var explorationFinalEps: Double = 0.05
    var targetUpdateInterval: Int = 10_000
    var learningStarts: Int = 1_000
    var netArch: [Int] = [64, 64]
    var trainFrequency: Int = 4
    var trainFrequencyUnit: String = "step"
    var gradientSteps: Int = 1
    var gradientStepsMode: GradientStepsMode = .fixed
    var maxGradNorm: Double = 10.0
    var optimizeMemoryUsage: Bool = false
    var handleTimeoutTermination: Bool = true
    var activation: String = "relu"
    var normalizeImages: Bool = true
    var optimizerBeta1: Float = 0.9
    var optimizerBeta2: Float = 0.999
    var optimizerEps: Float = 1e-8

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        learningRate = try c.decodeIfPresent(Float.self, forKey: .learningRate) ?? 1e-4
        learningRateSchedule = try c.decodeIfPresent(String.self, forKey: .learningRateSchedule) ?? "constant"
        learningRateFinal = try c.decodeIfPresent(Float.self, forKey: .learningRateFinal) ?? 0.0
        learningRateDecayRate = try c.decodeIfPresent(Float.self, forKey: .learningRateDecayRate) ?? 0.99
        learningRateMinValue = try c.decodeIfPresent(Float.self, forKey: .learningRateMinValue) ?? 0.0
        learningRateMilestones = try c.decodeIfPresent(String.self, forKey: .learningRateMilestones) ?? "0.5,0.75"
        learningRateGamma = try c.decodeIfPresent(Float.self, forKey: .learningRateGamma) ?? 0.1
        warmupEnabled = try c.decodeIfPresent(Bool.self, forKey: .warmupEnabled) ?? false
        warmupFraction = try c.decodeIfPresent(Double.self, forKey: .warmupFraction) ?? 0.05
        warmupInitialValue = try c.decodeIfPresent(Float.self, forKey: .warmupInitialValue) ?? 0.0
        bufferSize = try c.decodeIfPresent(Int.self, forKey: .bufferSize) ?? 1_000_000
        batchSize = try c.decodeIfPresent(Int.self, forKey: .batchSize) ?? 32
        gamma = try c.decodeIfPresent(Double.self, forKey: .gamma) ?? 0.99
        tau = try c.decodeIfPresent(Double.self, forKey: .tau) ?? 1.0
        explorationFraction = try c.decodeIfPresent(Double.self, forKey: .explorationFraction) ?? 0.2
        explorationInitialEps = try c.decodeIfPresent(Double.self, forKey: .explorationInitialEps) ?? 1.0
        explorationFinalEps = try c.decodeIfPresent(Double.self, forKey: .explorationFinalEps) ?? 0.05
        targetUpdateInterval = try c.decodeIfPresent(Int.self, forKey: .targetUpdateInterval) ?? 10_000
        learningStarts = try c.decodeIfPresent(Int.self, forKey: .learningStarts) ?? 1_000
        netArch = try c.decodeIfPresent([Int].self, forKey: .netArch) ?? [64, 64]
        trainFrequency = try c.decodeIfPresent(Int.self, forKey: .trainFrequency) ?? 4
        trainFrequencyUnit = try c.decodeIfPresent(String.self, forKey: .trainFrequencyUnit) ?? "step"
        gradientSteps = try c.decodeIfPresent(Int.self, forKey: .gradientSteps) ?? 1
        gradientStepsMode =
            try c.decodeIfPresent(GradientStepsMode.self, forKey: .gradientStepsMode) ?? .fixed
        maxGradNorm = try c.decodeIfPresent(Double.self, forKey: .maxGradNorm) ?? 10.0
        optimizeMemoryUsage = try c.decodeIfPresent(Bool.self, forKey: .optimizeMemoryUsage) ?? false
        handleTimeoutTermination = try c.decodeIfPresent(Bool.self, forKey: .handleTimeoutTermination) ?? true
        activation = try c.decodeIfPresent(String.self, forKey: .activation) ?? "relu"
        normalizeImages = try c.decodeIfPresent(Bool.self, forKey: .normalizeImages) ?? true
        optimizerBeta1 = try c.decodeIfPresent(Float.self, forKey: .optimizerBeta1) ?? 0.9
        optimizerBeta2 = try c.decodeIfPresent(Float.self, forKey: .optimizerBeta2) ?? 0.999
        optimizerEps = try c.decodeIfPresent(Float.self, forKey: .optimizerEps) ?? 1e-8
    }
}

//
//  SACHyperparameters.swift
//  ExploreRL
//

import Foundation

struct SACHyperparameters: Equatable, Codable {
    var learningRate: Float = 3e-4
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
    var batchSize: Int = 256
    var gamma: Double = 0.99
    var tau: Double = 0.005
    var targetUpdateInterval: Int = 1
    var gradientSteps: Int = 1
    var gradientStepsMode: String = "fixed"
    var trainFrequency: Int = 1
    var trainFrequencyUnit: String = "step"
    var learningStarts: Int = 100
    var autoEntropyTuning: Bool = true
    var autoEntropyInit: Float = 1.0
    var fixedEntCoef: Float = 0.2
    var useTargetEntropy: Bool = false
    var targetEntropy: Float = 0.0
    var netArch: [Int] = [256, 256]
    var useSeparateNetworks: Bool = false
    var criticNetArch: [Int] = [256, 256]
    var activation: String = "relu"
    var normalizeImages: Bool = true
    var useSDE: Bool = false
    var useSDEAtWarmup: Bool = false
    var sdeSampleFreq: Int = -1
    var logStdInit: Float = -3.0
    var fullStd: Bool = true
    var clipMean: Float = 2.0
    var nCritics: Int = 2
    var shareFeaturesExtractor: Bool = false
    var criticActivation: String = "relu"
    var criticNormalizeImages: Bool = true
    var optimizeMemoryUsage: Bool = false
    var handleTimeoutTermination: Bool = true
    var optimizerActorBeta1: Float = 0.9
    var optimizerActorBeta2: Float = 0.999
    var optimizerActorEps: Float = 1e-8
    var optimizerCriticBeta1: Float = 0.9
    var optimizerCriticBeta2: Float = 0.999
    var optimizerCriticEps: Float = 1e-8
    var optimizerEntropyBeta1: Float = 0.9
    var optimizerEntropyBeta2: Float = 0.999
    var optimizerEntropyEps: Float = 1e-8

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        learningRate = try c.decodeIfPresent(Float.self, forKey: .learningRate) ?? 3e-4
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
        batchSize = try c.decodeIfPresent(Int.self, forKey: .batchSize) ?? 256
        gamma = try c.decodeIfPresent(Double.self, forKey: .gamma) ?? 0.99
        tau = try c.decodeIfPresent(Double.self, forKey: .tau) ?? 0.005
        targetUpdateInterval = try c.decodeIfPresent(Int.self, forKey: .targetUpdateInterval) ?? 1
        gradientSteps = try c.decodeIfPresent(Int.self, forKey: .gradientSteps) ?? 1
        gradientStepsMode = try c.decodeIfPresent(String.self, forKey: .gradientStepsMode) ?? "fixed"
        trainFrequency = try c.decodeIfPresent(Int.self, forKey: .trainFrequency) ?? 1
        trainFrequencyUnit = try c.decodeIfPresent(String.self, forKey: .trainFrequencyUnit) ?? "step"
        learningStarts = try c.decodeIfPresent(Int.self, forKey: .learningStarts) ?? 100
        autoEntropyTuning = try c.decodeIfPresent(Bool.self, forKey: .autoEntropyTuning) ?? true
        autoEntropyInit = try c.decodeIfPresent(Float.self, forKey: .autoEntropyInit) ?? 1.0
        fixedEntCoef = try c.decodeIfPresent(Float.self, forKey: .fixedEntCoef) ?? 0.2
        useTargetEntropy = try c.decodeIfPresent(Bool.self, forKey: .useTargetEntropy) ?? false
        targetEntropy = try c.decodeIfPresent(Float.self, forKey: .targetEntropy) ?? 0.0
        netArch = try c.decodeIfPresent([Int].self, forKey: .netArch) ?? [256, 256]
        useSeparateNetworks = try c.decodeIfPresent(Bool.self, forKey: .useSeparateNetworks) ?? false
        criticNetArch = try c.decodeIfPresent([Int].self, forKey: .criticNetArch) ?? [256, 256]
        activation = try c.decodeIfPresent(String.self, forKey: .activation) ?? "relu"
        normalizeImages = try c.decodeIfPresent(Bool.self, forKey: .normalizeImages) ?? true
        useSDE = try c.decodeIfPresent(Bool.self, forKey: .useSDE) ?? false
        useSDEAtWarmup = try c.decodeIfPresent(Bool.self, forKey: .useSDEAtWarmup) ?? false
        sdeSampleFreq = try c.decodeIfPresent(Int.self, forKey: .sdeSampleFreq) ?? -1
        logStdInit = try c.decodeIfPresent(Float.self, forKey: .logStdInit) ?? -3.0
        fullStd = try c.decodeIfPresent(Bool.self, forKey: .fullStd) ?? true
        clipMean = try c.decodeIfPresent(Float.self, forKey: .clipMean) ?? 2.0
        nCritics = try c.decodeIfPresent(Int.self, forKey: .nCritics) ?? 2
        shareFeaturesExtractor = try c.decodeIfPresent(Bool.self, forKey: .shareFeaturesExtractor) ?? false
        criticActivation = try c.decodeIfPresent(String.self, forKey: .criticActivation) ?? "relu"
        criticNormalizeImages = try c.decodeIfPresent(Bool.self, forKey: .criticNormalizeImages) ?? true
        optimizeMemoryUsage = try c.decodeIfPresent(Bool.self, forKey: .optimizeMemoryUsage) ?? false
        handleTimeoutTermination = try c.decodeIfPresent(Bool.self, forKey: .handleTimeoutTermination) ?? true
        optimizerActorBeta1 = try c.decodeIfPresent(Float.self, forKey: .optimizerActorBeta1) ?? 0.9
        optimizerActorBeta2 = try c.decodeIfPresent(Float.self, forKey: .optimizerActorBeta2) ?? 0.999
        optimizerActorEps = try c.decodeIfPresent(Float.self, forKey: .optimizerActorEps) ?? 1e-8
        optimizerCriticBeta1 = try c.decodeIfPresent(Float.self, forKey: .optimizerCriticBeta1) ?? 0.9
        optimizerCriticBeta2 = try c.decodeIfPresent(Float.self, forKey: .optimizerCriticBeta2) ?? 0.999
        optimizerCriticEps = try c.decodeIfPresent(Float.self, forKey: .optimizerCriticEps) ?? 1e-8
        optimizerEntropyBeta1 = try c.decodeIfPresent(Float.self, forKey: .optimizerEntropyBeta1) ?? 0.9
        optimizerEntropyBeta2 = try c.decodeIfPresent(Float.self, forKey: .optimizerEntropyBeta2) ?? 0.999
        optimizerEntropyEps = try c.decodeIfPresent(Float.self, forKey: .optimizerEntropyEps) ?? 1e-8
    }
}

import Foundation

struct TD3Hyperparameters: Equatable, Codable {
    var learningRate: Float = 1e-3
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
    var batchSize: Int = 100
    var gamma: Double = 0.99
    var tau: Double = 0.005
    var learningStarts: Int = 100
    var trainFrequency: Int = 1
    var trainFrequencyUnit: String = "step"
    var gradientSteps: Int = 1
    var gradientStepsMode: GradientStepsMode = .fixed
    var policyDelay: Int = 2
    var targetPolicyNoise: Float = 0.2
    var targetNoiseClip: Float = 0.5
    var actionNoiseType: String = "normal"
    var actionNoiseStd: Float = 0.1
    var ouTheta: Float = 0.15
    var ouDt: Float = 0.01
    var ouInitialNoise: Float = 0.0
    var netArch: [Int] = [400, 300]
    var nCritics: Int = 2
    var shareFeaturesExtractor: Bool = false
    var activation: String = "relu"
    var normalizeImages: Bool = true
    var optimizeMemoryUsage: Bool = false
    var handleTimeoutTermination: Bool = true
    var optimizerActorBeta1: Float = 0.9
    var optimizerActorBeta2: Float = 0.999
    var optimizerActorEps: Float = 1e-8
    var optimizerCriticBeta1: Float = 0.9
    var optimizerCriticBeta2: Float = 0.999
    var optimizerCriticEps: Float = 1e-8

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        learningRate = try c.decodeIfPresent(Float.self, forKey: .learningRate) ?? 1e-3
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
        batchSize = try c.decodeIfPresent(Int.self, forKey: .batchSize) ?? 100
        gamma = try c.decodeIfPresent(Double.self, forKey: .gamma) ?? 0.99
        tau = try c.decodeIfPresent(Double.self, forKey: .tau) ?? 0.005
        learningStarts = try c.decodeIfPresent(Int.self, forKey: .learningStarts) ?? 100
        trainFrequency = try c.decodeIfPresent(Int.self, forKey: .trainFrequency) ?? 1
        trainFrequencyUnit = try c.decodeIfPresent(String.self, forKey: .trainFrequencyUnit) ?? "step"
        gradientSteps = try c.decodeIfPresent(Int.self, forKey: .gradientSteps) ?? 1
        gradientStepsMode =
            try c.decodeIfPresent(GradientStepsMode.self, forKey: .gradientStepsMode) ?? .fixed
        policyDelay = try c.decodeIfPresent(Int.self, forKey: .policyDelay) ?? 2
        targetPolicyNoise = try c.decodeIfPresent(Float.self, forKey: .targetPolicyNoise) ?? 0.2
        targetNoiseClip = try c.decodeIfPresent(Float.self, forKey: .targetNoiseClip) ?? 0.5
        actionNoiseType = try c.decodeIfPresent(String.self, forKey: .actionNoiseType) ?? "normal"
        actionNoiseStd = try c.decodeIfPresent(Float.self, forKey: .actionNoiseStd) ?? 0.1
        ouTheta = try c.decodeIfPresent(Float.self, forKey: .ouTheta) ?? 0.15
        ouDt = try c.decodeIfPresent(Float.self, forKey: .ouDt) ?? 0.01
        ouInitialNoise = try c.decodeIfPresent(Float.self, forKey: .ouInitialNoise) ?? 0.0
        netArch = try c.decodeIfPresent([Int].self, forKey: .netArch) ?? [400, 300]
        nCritics = try c.decodeIfPresent(Int.self, forKey: .nCritics) ?? 2
        shareFeaturesExtractor = try c.decodeIfPresent(Bool.self, forKey: .shareFeaturesExtractor) ?? false
        activation = try c.decodeIfPresent(String.self, forKey: .activation) ?? "relu"
        normalizeImages = try c.decodeIfPresent(Bool.self, forKey: .normalizeImages) ?? true
        optimizeMemoryUsage = try c.decodeIfPresent(Bool.self, forKey: .optimizeMemoryUsage) ?? false
        handleTimeoutTermination = try c.decodeIfPresent(Bool.self, forKey: .handleTimeoutTermination) ?? true
        optimizerActorBeta1 = try c.decodeIfPresent(Float.self, forKey: .optimizerActorBeta1) ?? 0.9
        optimizerActorBeta2 = try c.decodeIfPresent(Float.self, forKey: .optimizerActorBeta2) ?? 0.999
        optimizerActorEps = try c.decodeIfPresent(Float.self, forKey: .optimizerActorEps) ?? 1e-8
        optimizerCriticBeta1 = try c.decodeIfPresent(Float.self, forKey: .optimizerCriticBeta1) ?? 0.9
        optimizerCriticBeta2 = try c.decodeIfPresent(Float.self, forKey: .optimizerCriticBeta2) ?? 0.999
        optimizerCriticEps = try c.decodeIfPresent(Float.self, forKey: .optimizerCriticEps) ?? 1e-8
    }
}

import Foundation

struct PPOHyperparameters: Equatable, Codable {
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
    var nSteps: Int = 2048
    var batchSize: Int = 64
    var nEpochs: Int = 10
    var gamma: Double = 0.99
    var gaeLambda: Double = 0.95
    var clipRange: Double = 0.2
    var clipRangeVfEnabled: Bool = false
    var clipRangeVf: Double = 0.2
    var normalizeAdvantage: Bool = true
    var entCoef: Double = 0.0
    var vfCoef: Double = 0.5
    var maxGradNorm: Double = 0.5
    var targetKLEnabled: Bool = false
    var targetKL: Double = 0.03
    var useSDE: Bool = false
    var sdeSampleFreq: Int = -1
    var netArch: [Int] = [64, 64]
    var activation: String = "tanh"
    var normalizeImages: Bool = true
    var shareFeaturesExtractor: Bool = true
    var orthoInit: Bool = true
    var logStdInit: Float = 0.0
    var fullStd: Bool = true

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
        nSteps = try c.decodeIfPresent(Int.self, forKey: .nSteps) ?? 2048
        batchSize = try c.decodeIfPresent(Int.self, forKey: .batchSize) ?? 64
        nEpochs = try c.decodeIfPresent(Int.self, forKey: .nEpochs) ?? 10
        gamma = try c.decodeIfPresent(Double.self, forKey: .gamma) ?? 0.99
        gaeLambda = try c.decodeIfPresent(Double.self, forKey: .gaeLambda) ?? 0.95
        clipRange = try c.decodeIfPresent(Double.self, forKey: .clipRange) ?? 0.2
        clipRangeVfEnabled = try c.decodeIfPresent(Bool.self, forKey: .clipRangeVfEnabled) ?? false
        clipRangeVf = try c.decodeIfPresent(Double.self, forKey: .clipRangeVf) ?? 0.2
        normalizeAdvantage = try c.decodeIfPresent(Bool.self, forKey: .normalizeAdvantage) ?? true
        entCoef = try c.decodeIfPresent(Double.self, forKey: .entCoef) ?? 0.0
        vfCoef = try c.decodeIfPresent(Double.self, forKey: .vfCoef) ?? 0.5
        maxGradNorm = try c.decodeIfPresent(Double.self, forKey: .maxGradNorm) ?? 0.5
        targetKLEnabled = try c.decodeIfPresent(Bool.self, forKey: .targetKLEnabled) ?? false
        targetKL = try c.decodeIfPresent(Double.self, forKey: .targetKL) ?? 0.03
        useSDE = try c.decodeIfPresent(Bool.self, forKey: .useSDE) ?? false
        sdeSampleFreq = try c.decodeIfPresent(Int.self, forKey: .sdeSampleFreq) ?? -1
        netArch = try c.decodeIfPresent([Int].self, forKey: .netArch) ?? [64, 64]
        activation = try c.decodeIfPresent(String.self, forKey: .activation) ?? "tanh"
        normalizeImages = try c.decodeIfPresent(Bool.self, forKey: .normalizeImages) ?? true
        shareFeaturesExtractor =
            try c.decodeIfPresent(Bool.self, forKey: .shareFeaturesExtractor) ?? true
        orthoInit = try c.decodeIfPresent(Bool.self, forKey: .orthoInit) ?? true
        logStdInit = try c.decodeIfPresent(Float.self, forKey: .logStdInit) ?? 0.0
        fullStd = try c.decodeIfPresent(Bool.self, forKey: .fullStd) ?? true
    }
}

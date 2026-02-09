//
//  HyperparameterAccessor.swift
//  ExploreRL
//

import Foundation

struct HyperparameterAccessor {
    let config: TrainingConfig

    func doubleValue(for id: String) -> Double {
        switch config.algorithm {
        case .qLearning, .sarsa:
            switch id {
            case "learningRate": return config.tabular.learningRate
            case "gamma": return config.tabular.gamma
            case "epsilon": return config.tabular.epsilon
            case "epsilonDecay": return config.tabular.epsilonDecay
            case "minEpsilon": return config.tabular.minEpsilon
            default: return 0
            }
        case .dqn:
            switch id {
            case "gamma": return config.dqn.gamma
            case "tau": return config.dqn.tau
            case "explorationFraction": return config.dqn.explorationFraction
            case "explorationInitialEps": return config.dqn.explorationInitialEps
            case "explorationFinalEps": return config.dqn.explorationFinalEps
            case "maxGradNorm": return config.dqn.maxGradNorm
            case "warmupFraction": return config.dqn.warmupFraction
            default: return 0
            }
        case .sac:
            switch id {
            case "gamma": return config.sac.gamma
            case "tau": return config.sac.tau
            case "warmupFraction": return config.sac.warmupFraction
            default: return 0
            }
        }
    }

    func floatValue(for id: String) -> Float {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "learningRate": return config.dqn.learningRate
            case "learningRateFinal": return config.dqn.learningRateFinal
            case "learningRateDecayRate": return config.dqn.learningRateDecayRate
            case "learningRateMinValue": return config.dqn.learningRateMinValue
            case "learningRateGamma": return config.dqn.learningRateGamma
            case "warmupInitialValue": return config.dqn.warmupInitialValue
            case "optimizerBeta1": return config.dqn.optimizerBeta1
            case "optimizerBeta2": return config.dqn.optimizerBeta2
            case "optimizerEps": return config.dqn.optimizerEps
            default: break
            }
        case .sac:
            switch id {
            case "learningRate": return config.sac.learningRate
            case "learningRateFinal": return config.sac.learningRateFinal
            case "learningRateDecayRate": return config.sac.learningRateDecayRate
            case "learningRateMinValue": return config.sac.learningRateMinValue
            case "learningRateGamma": return config.sac.learningRateGamma
            case "warmupInitialValue": return config.sac.warmupInitialValue
            case "fixedEntCoef": return config.sac.fixedEntCoef
            case "autoEntropyInit": return config.sac.autoEntropyInit
            case "targetEntropy": return config.sac.targetEntropy
            case "logStdInit": return config.sac.logStdInit
            case "clipMean": return config.sac.clipMean
            case "optimizerActorBeta1": return config.sac.optimizerActorBeta1
            case "optimizerActorBeta2": return config.sac.optimizerActorBeta2
            case "optimizerActorEps": return config.sac.optimizerActorEps
            case "optimizerCriticBeta1": return config.sac.optimizerCriticBeta1
            case "optimizerCriticBeta2": return config.sac.optimizerCriticBeta2
            case "optimizerCriticEps": return config.sac.optimizerCriticEps
            case "optimizerEntropyBeta1": return config.sac.optimizerEntropyBeta1
            case "optimizerEntropyBeta2": return config.sac.optimizerEntropyBeta2
            case "optimizerEntropyEps": return config.sac.optimizerEntropyEps
            default: break
            }
        default:
            break
        }
        return 0
    }

    func intValue(for id: String) -> Int {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "batchSize": return config.dqn.batchSize
            case "bufferSize": return config.dqn.bufferSize
            case "learningStarts": return config.dqn.learningStarts
            case "targetUpdateInterval": return config.dqn.targetUpdateInterval
            case "trainFrequency": return config.dqn.trainFrequency
            case "gradientSteps": return config.dqn.gradientSteps
            default: return 0
            }
        case .sac:
            switch id {
            case "batchSize": return config.sac.batchSize
            case "bufferSize": return config.sac.bufferSize
            case "learningStarts": return config.sac.learningStarts
            case "targetUpdateInterval": return config.sac.targetUpdateInterval
            case "gradientSteps": return config.sac.gradientSteps
            case "trainFrequency": return config.sac.trainFrequency
            case "sdeSampleFreq": return config.sac.sdeSampleFreq
            case "nCritics": return config.sac.nCritics
            default: return 0
            }
        default:
            return 0
        }
    }

    func boolValue(for id: String) -> Bool {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "optimizeMemoryUsage": return config.dqn.optimizeMemoryUsage
            case "handleTimeoutTermination": return config.dqn.handleTimeoutTermination
            case "normalizeImages": return config.dqn.normalizeImages
            case "warmupEnabled": return config.dqn.warmupEnabled
            default: return false
            }
        case .sac:
            switch id {
            case "autoEntropyTuning": return config.sac.autoEntropyTuning
            case "useTargetEntropy": return config.sac.useTargetEntropy
            case "useSeparateNetworks": return config.sac.useSeparateNetworks
            case "normalizeImages": return config.sac.normalizeImages
            case "useSDE": return config.sac.useSDE
            case "useSDEAtWarmup": return config.sac.useSDEAtWarmup
            case "fullStd": return config.sac.fullStd
            case "shareFeaturesExtractor": return config.sac.shareFeaturesExtractor
            case "criticNormalizeImages": return config.sac.criticNormalizeImages
            case "optimizeMemoryUsage": return config.sac.optimizeMemoryUsage
            case "handleTimeoutTermination": return config.sac.handleTimeoutTermination
            case "warmupEnabled": return config.sac.warmupEnabled
            default: return false
            }
        default:
            return false
        }
    }

    func stringValue(for id: String) -> String {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "netArch": return Self.formatIntList(config.dqn.netArch)
            case "learningRateSchedule": return config.dqn.learningRateSchedule
            case "learningRateMilestones": return config.dqn.learningRateMilestones
            case "activation": return config.dqn.activation
            case "trainFrequencyUnit": return config.dqn.trainFrequencyUnit
            case "gradientStepsMode": return config.dqn.gradientStepsMode
            default: return ""
            }
        case .sac:
            switch id {
            case "netArch": return Self.formatIntList(config.sac.netArch)
            case "criticNetArch": return Self.formatIntList(config.sac.criticNetArch)
            case "learningRateSchedule": return config.sac.learningRateSchedule
            case "learningRateMilestones": return config.sac.learningRateMilestones
            case "activation": return config.sac.activation
            case "trainFrequencyUnit": return config.sac.trainFrequencyUnit
            case "gradientStepsMode": return config.sac.gradientStepsMode
            case "criticActivation": return config.sac.criticActivation
            default: return ""
            }
        default:
            return ""
        }
    }

    static func setDouble(id: String, value: Double, on config: inout TrainingConfig) {
        switch config.algorithm {
        case .qLearning, .sarsa:
            switch id {
            case "learningRate": config.tabular.learningRate = value
            case "gamma": config.tabular.gamma = value
            case "epsilon": config.tabular.epsilon = value
            case "epsilonDecay": config.tabular.epsilonDecay = value
            case "minEpsilon": config.tabular.minEpsilon = value
            default: break
            }
        case .dqn:
            switch id {
            case "gamma": config.dqn.gamma = value
            case "tau": config.dqn.tau = value
            case "explorationFraction": config.dqn.explorationFraction = value
            case "explorationInitialEps": config.dqn.explorationInitialEps = value
            case "explorationFinalEps": config.dqn.explorationFinalEps = value
            case "maxGradNorm": config.dqn.maxGradNorm = value
            case "warmupFraction": config.dqn.warmupFraction = value
            default: break
            }
        case .sac:
            switch id {
            case "gamma": config.sac.gamma = value
            case "tau": config.sac.tau = value
            case "warmupFraction": config.sac.warmupFraction = value
            default: break
            }
        }
    }

    static func setFloat(id: String, value: Float, on config: inout TrainingConfig) {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "learningRate": config.dqn.learningRate = value
            case "learningRateFinal": config.dqn.learningRateFinal = value
            case "learningRateDecayRate": config.dqn.learningRateDecayRate = value
            case "learningRateMinValue": config.dqn.learningRateMinValue = value
            case "learningRateGamma": config.dqn.learningRateGamma = value
            case "warmupInitialValue": config.dqn.warmupInitialValue = value
            case "optimizerBeta1": config.dqn.optimizerBeta1 = value
            case "optimizerBeta2": config.dqn.optimizerBeta2 = value
            case "optimizerEps": config.dqn.optimizerEps = value
            default: break
            }
        case .sac:
            switch id {
            case "learningRate": config.sac.learningRate = value
            case "learningRateFinal": config.sac.learningRateFinal = value
            case "learningRateDecayRate": config.sac.learningRateDecayRate = value
            case "learningRateMinValue": config.sac.learningRateMinValue = value
            case "learningRateGamma": config.sac.learningRateGamma = value
            case "warmupInitialValue": config.sac.warmupInitialValue = value
            case "fixedEntCoef": config.sac.fixedEntCoef = value
            case "autoEntropyInit": config.sac.autoEntropyInit = value
            case "targetEntropy": config.sac.targetEntropy = value
            case "logStdInit": config.sac.logStdInit = value
            case "clipMean": config.sac.clipMean = value
            case "optimizerActorBeta1": config.sac.optimizerActorBeta1 = value
            case "optimizerActorBeta2": config.sac.optimizerActorBeta2 = value
            case "optimizerActorEps": config.sac.optimizerActorEps = value
            case "optimizerCriticBeta1": config.sac.optimizerCriticBeta1 = value
            case "optimizerCriticBeta2": config.sac.optimizerCriticBeta2 = value
            case "optimizerCriticEps": config.sac.optimizerCriticEps = value
            case "optimizerEntropyBeta1": config.sac.optimizerEntropyBeta1 = value
            case "optimizerEntropyBeta2": config.sac.optimizerEntropyBeta2 = value
            case "optimizerEntropyEps": config.sac.optimizerEntropyEps = value
            default: break
            }
        default:
            break
        }
    }

    static func setInt(id: String, value: Int, on config: inout TrainingConfig) {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "batchSize": config.dqn.batchSize = value
            case "bufferSize": config.dqn.bufferSize = value
            case "learningStarts": config.dqn.learningStarts = value
            case "targetUpdateInterval": config.dqn.targetUpdateInterval = value
            case "trainFrequency": config.dqn.trainFrequency = value
            case "gradientSteps": config.dqn.gradientSteps = value
            default: break
            }
        case .sac:
            switch id {
            case "batchSize": config.sac.batchSize = value
            case "bufferSize": config.sac.bufferSize = value
            case "learningStarts": config.sac.learningStarts = value
            case "targetUpdateInterval": config.sac.targetUpdateInterval = value
            case "gradientSteps": config.sac.gradientSteps = value
            case "trainFrequency": config.sac.trainFrequency = value
            case "sdeSampleFreq": config.sac.sdeSampleFreq = value
            case "nCritics": config.sac.nCritics = value
            default: break
            }
        default:
            break
        }
    }

    static func setBool(id: String, value: Bool, on config: inout TrainingConfig) {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "optimizeMemoryUsage": config.dqn.optimizeMemoryUsage = value
            case "handleTimeoutTermination": config.dqn.handleTimeoutTermination = value
            case "normalizeImages": config.dqn.normalizeImages = value
            case "warmupEnabled": config.dqn.warmupEnabled = value
            default: break
            }
        case .sac:
            switch id {
            case "autoEntropyTuning": config.sac.autoEntropyTuning = value
            case "useTargetEntropy": config.sac.useTargetEntropy = value
            case "useSeparateNetworks": config.sac.useSeparateNetworks = value
            case "normalizeImages": config.sac.normalizeImages = value
            case "useSDE": config.sac.useSDE = value
            case "useSDEAtWarmup": config.sac.useSDEAtWarmup = value
            case "fullStd": config.sac.fullStd = value
            case "shareFeaturesExtractor": config.sac.shareFeaturesExtractor = value
            case "criticNormalizeImages": config.sac.criticNormalizeImages = value
            case "optimizeMemoryUsage": config.sac.optimizeMemoryUsage = value
            case "handleTimeoutTermination": config.sac.handleTimeoutTermination = value
            case "warmupEnabled": config.sac.warmupEnabled = value
            default: break
            }
        default:
            break
        }
    }

    static func setString(id: String, value: String, on config: inout TrainingConfig) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch config.algorithm {
        case .dqn:
            switch id {
            case "netArch":
                let parsed = parseIntList(trimmed)
                if !parsed.isEmpty { config.dqn.netArch = parsed }
            case "learningRateSchedule":
                if ["constant", "linear", "exponential", "step", "cosine"].contains(trimmed) {
                    config.dqn.learningRateSchedule = trimmed
                }
            case "learningRateMilestones":
                config.dqn.learningRateMilestones = trimmed
            case "activation":
                config.dqn.activation = trimmed
            case "trainFrequencyUnit":
                if ["step", "episode"].contains(trimmed) {
                    config.dqn.trainFrequencyUnit = trimmed
                }
            case "gradientStepsMode":
                if ["fixed", "asCollectedSteps"].contains(trimmed) {
                    config.dqn.gradientStepsMode = trimmed
                }
            default:
                break
            }
        case .sac:
            switch id {
            case "netArch":
                let parsed = parseIntList(trimmed)
                if !parsed.isEmpty { config.sac.netArch = parsed }
            case "criticNetArch":
                let parsed = parseIntList(trimmed)
                if !parsed.isEmpty { config.sac.criticNetArch = parsed }
            case "learningRateSchedule":
                if ["constant", "linear", "exponential", "step", "cosine"].contains(trimmed) {
                    config.sac.learningRateSchedule = trimmed
                }
            case "learningRateMilestones":
                config.sac.learningRateMilestones = trimmed
            case "activation":
                config.sac.activation = trimmed
            case "trainFrequencyUnit":
                if ["step", "episode"].contains(trimmed) {
                    config.sac.trainFrequencyUnit = trimmed
                }
            case "gradientStepsMode":
                if ["fixed", "asCollectedSteps"].contains(trimmed) {
                    config.sac.gradientStepsMode = trimmed
                }
            case "criticActivation":
                config.sac.criticActivation = trimmed
            default:
                break
            }
        default:
            break
        }
    }

    private static func formatIntList(_ values: [Int]) -> String {
        values.map(String.init).joined(separator: ",")
    }

    private static func parseIntList(_ value: String) -> [Int] {
        let parts = value.split { char in
            char == "," || char == " " || char == "\n" || char == "\t" || char == ";"
        }
        return parts.compactMap { Int($0) }.filter { $0 > 0 }
    }
}

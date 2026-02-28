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
        case .ppo:
            switch id {
            case "gamma": return config.ppo.gamma
            case "gaeLambda": return config.ppo.gaeLambda
            case "clipRange": return config.ppo.clipRange
            case "clipRangeVf": return config.ppo.clipRangeVf
            case "entCoef": return config.ppo.entCoef
            case "vfCoef": return config.ppo.vfCoef
            case "maxGradNorm": return config.ppo.maxGradNorm
            case "targetKL": return config.ppo.targetKL
            case "warmupFraction": return config.ppo.warmupFraction
            default: return 0
            }
        case .sac:
            switch id {
            case "gamma": return config.sac.gamma
            case "tau": return config.sac.tau
            case "warmupFraction": return config.sac.warmupFraction
            default: return 0
            }
        case .td3:
            switch id {
            case "gamma": return config.td3.gamma
            case "tau": return config.td3.tau
            case "warmupFraction": return config.td3.warmupFraction
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
        case .ppo:
            switch id {
            case "learningRate": return config.ppo.learningRate
            case "learningRateFinal": return config.ppo.learningRateFinal
            case "learningRateDecayRate": return config.ppo.learningRateDecayRate
            case "learningRateMinValue": return config.ppo.learningRateMinValue
            case "learningRateGamma": return config.ppo.learningRateGamma
            case "warmupInitialValue": return config.ppo.warmupInitialValue
            case "logStdInit": return config.ppo.logStdInit
            default: break
            }
        case .td3:
            switch id {
            case "learningRate": return config.td3.learningRate
            case "learningRateFinal": return config.td3.learningRateFinal
            case "learningRateDecayRate": return config.td3.learningRateDecayRate
            case "learningRateMinValue": return config.td3.learningRateMinValue
            case "learningRateGamma": return config.td3.learningRateGamma
            case "warmupInitialValue": return config.td3.warmupInitialValue
            case "targetPolicyNoise": return config.td3.targetPolicyNoise
            case "targetNoiseClip": return config.td3.targetNoiseClip
            case "actionNoiseStd": return config.td3.actionNoiseStd
            case "ouTheta": return config.td3.ouTheta
            case "ouDt": return config.td3.ouDt
            case "ouInitialNoise": return config.td3.ouInitialNoise
            case "optimizerActorBeta1": return config.td3.optimizerActorBeta1
            case "optimizerActorBeta2": return config.td3.optimizerActorBeta2
            case "optimizerActorEps": return config.td3.optimizerActorEps
            case "optimizerCriticBeta1": return config.td3.optimizerCriticBeta1
            case "optimizerCriticBeta2": return config.td3.optimizerCriticBeta2
            case "optimizerCriticEps": return config.td3.optimizerCriticEps
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
        case .ppo:
            switch id {
            case "nSteps": return config.ppo.nSteps
            case "batchSize": return config.ppo.batchSize
            case "nEpochs": return config.ppo.nEpochs
            case "sdeSampleFreq": return config.ppo.sdeSampleFreq
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
        case .td3:
            switch id {
            case "batchSize": return config.td3.batchSize
            case "bufferSize": return config.td3.bufferSize
            case "learningStarts": return config.td3.learningStarts
            case "gradientSteps": return config.td3.gradientSteps
            case "trainFrequency": return config.td3.trainFrequency
            case "policyDelay": return config.td3.policyDelay
            case "nCritics": return config.td3.nCritics
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
        case .ppo:
            switch id {
            case "clipRangeVfEnabled": return config.ppo.clipRangeVfEnabled
            case "normalizeAdvantage": return config.ppo.normalizeAdvantage
            case "targetKLEnabled": return config.ppo.targetKLEnabled
            case "useSDE": return config.ppo.useSDE
            case "normalizeImages": return config.ppo.normalizeImages
            case "shareFeaturesExtractor": return config.ppo.shareFeaturesExtractor
            case "orthoInit": return config.ppo.orthoInit
            case "fullStd": return config.ppo.fullStd
            case "warmupEnabled": return config.ppo.warmupEnabled
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
        case .td3:
            switch id {
            case "shareFeaturesExtractor": return config.td3.shareFeaturesExtractor
            case "normalizeImages": return config.td3.normalizeImages
            case "optimizeMemoryUsage": return config.td3.optimizeMemoryUsage
            case "handleTimeoutTermination": return config.td3.handleTimeoutTermination
            case "warmupEnabled": return config.td3.warmupEnabled
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
            case "gradientStepsMode":
                return normalizedGradientStepsMode(
                    mode: config.dqn.gradientStepsMode,
                    count: config.dqn.gradientSteps
                ).rawValue
            default: return ""
            }
        case .ppo:
            switch id {
            case "netArch": return Self.formatIntList(config.ppo.netArch)
            case "learningRateSchedule": return config.ppo.learningRateSchedule
            case "learningRateMilestones": return config.ppo.learningRateMilestones
            case "activation": return config.ppo.activation
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
            case "gradientStepsMode":
                return normalizedGradientStepsMode(
                    mode: config.sac.gradientStepsMode,
                    count: config.sac.gradientSteps
                ).rawValue
            case "criticActivation": return config.sac.criticActivation
            default: return ""
            }
        case .td3:
            switch id {
            case "netArch": return Self.formatIntList(config.td3.netArch)
            case "learningRateSchedule": return config.td3.learningRateSchedule
            case "learningRateMilestones": return config.td3.learningRateMilestones
            case "activation": return config.td3.activation
            case "trainFrequencyUnit": return config.td3.trainFrequencyUnit
            case "gradientStepsMode":
                return normalizedGradientStepsMode(
                    mode: config.td3.gradientStepsMode,
                    count: config.td3.gradientSteps
                ).rawValue
            case "actionNoiseType": return config.td3.actionNoiseType
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
            case "gamma":
                config.dqn.gamma = clamp(value, min: 0.0, max: 1.0)
            case "tau":
                config.dqn.tau = clamp(value, min: 0.0, max: 1.0)
            case "explorationFraction":
                config.dqn.explorationFraction = clamp(value, min: 1e-9, max: 1.0)
            case "explorationInitialEps":
                let initial = clamp(value, min: 0.0, max: 1.0)
                config.dqn.explorationInitialEps = initial
                config.dqn.explorationFinalEps = min(config.dqn.explorationFinalEps, initial)
            case "explorationFinalEps":
                let final = clamp(value, min: 0.0, max: 1.0)
                config.dqn.explorationFinalEps = min(final, config.dqn.explorationInitialEps)
            case "maxGradNorm":
                config.dqn.maxGradNorm = max(0.0, value)
            case "warmupFraction":
                config.dqn.warmupFraction = clamp(value, min: 0.0, max: 1.0)
            default: break
            }
        case .ppo:
            switch id {
            case "gamma":
                config.ppo.gamma = clamp(value, min: 0.0, max: 1.0)
            case "gaeLambda":
                config.ppo.gaeLambda = clamp(value, min: 0.0, max: 1.0)
            case "clipRange":
                config.ppo.clipRange = max(0.0, value)
            case "clipRangeVf":
                config.ppo.clipRangeVf = max(0.0, value)
            case "entCoef":
                config.ppo.entCoef = max(0.0, value)
            case "vfCoef":
                config.ppo.vfCoef = max(0.0, value)
            case "maxGradNorm":
                config.ppo.maxGradNorm = max(0.0, value)
            case "targetKL":
                config.ppo.targetKL = max(0.0, value)
            case "warmupFraction":
                config.ppo.warmupFraction = clamp(value, min: 0.0, max: 1.0)
            default: break
            }
        case .sac:
            switch id {
            case "gamma":
                config.sac.gamma = clamp(value, min: 0.0, max: 1.0)
            case "tau":
                config.sac.tau = clamp(value, min: 0.0, max: 1.0)
            case "warmupFraction":
                config.sac.warmupFraction = clamp(value, min: 0.0, max: 1.0)
            default: break
            }
        case .td3:
            switch id {
            case "gamma":
                config.td3.gamma = clamp(value, min: 0.0, max: 1.0)
            case "tau":
                config.td3.tau = clamp(value, min: 0.0, max: 1.0)
            case "warmupFraction":
                config.td3.warmupFraction = clamp(value, min: 0.0, max: 1.0)
            default: break
            }
        }
    }

    static func setFloat(id: String, value: Float, on config: inout TrainingConfig) {
        switch config.algorithm {
        case .dqn:
            switch id {
            case "learningRate":
                config.dqn.learningRate = max(value, 1e-12)
            case "learningRateFinal":
                config.dqn.learningRateFinal = max(value, 0.0)
            case "learningRateDecayRate":
                config.dqn.learningRateDecayRate = max(value, 1e-6)
            case "learningRateMinValue":
                config.dqn.learningRateMinValue = max(value, 0.0)
            case "learningRateGamma":
                config.dqn.learningRateGamma = max(value, 1e-6)
            case "warmupInitialValue":
                config.dqn.warmupInitialValue = max(value, 0.0)
            case "optimizerBeta1":
                config.dqn.optimizerBeta1 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerBeta2":
                config.dqn.optimizerBeta2 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerEps":
                config.dqn.optimizerEps = max(value, 1e-12)
            default: break
            }
        case .sac:
            switch id {
            case "learningRate":
                config.sac.learningRate = max(value, 1e-12)
            case "learningRateFinal":
                config.sac.learningRateFinal = max(value, 0.0)
            case "learningRateDecayRate":
                config.sac.learningRateDecayRate = max(value, 1e-6)
            case "learningRateMinValue":
                config.sac.learningRateMinValue = max(value, 0.0)
            case "learningRateGamma":
                config.sac.learningRateGamma = max(value, 1e-6)
            case "warmupInitialValue":
                config.sac.warmupInitialValue = max(value, 0.0)
            case "fixedEntCoef":
                config.sac.fixedEntCoef = max(value, 0.0)
            case "autoEntropyInit":
                config.sac.autoEntropyInit = max(value, 1e-6)
            case "targetEntropy": config.sac.targetEntropy = value
            case "logStdInit": config.sac.logStdInit = value
            case "clipMean":
                config.sac.clipMean = max(value, 0.0)
            case "optimizerActorBeta1":
                config.sac.optimizerActorBeta1 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerActorBeta2":
                config.sac.optimizerActorBeta2 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerActorEps":
                config.sac.optimizerActorEps = max(value, 1e-12)
            case "optimizerCriticBeta1":
                config.sac.optimizerCriticBeta1 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerCriticBeta2":
                config.sac.optimizerCriticBeta2 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerCriticEps":
                config.sac.optimizerCriticEps = max(value, 1e-12)
            case "optimizerEntropyBeta1":
                config.sac.optimizerEntropyBeta1 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerEntropyBeta2":
                config.sac.optimizerEntropyBeta2 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerEntropyEps":
                config.sac.optimizerEntropyEps = max(value, 1e-12)
            default: break
            }
        case .ppo:
            switch id {
            case "learningRate":
                config.ppo.learningRate = max(value, 1e-12)
            case "learningRateFinal":
                config.ppo.learningRateFinal = max(value, 0.0)
            case "learningRateDecayRate":
                config.ppo.learningRateDecayRate = max(value, 1e-6)
            case "learningRateMinValue":
                config.ppo.learningRateMinValue = max(value, 0.0)
            case "learningRateGamma":
                config.ppo.learningRateGamma = max(value, 1e-6)
            case "warmupInitialValue":
                config.ppo.warmupInitialValue = max(value, 0.0)
            case "logStdInit":
                config.ppo.logStdInit = value
            default: break
            }
        case .td3:
            switch id {
            case "learningRate":
                config.td3.learningRate = max(value, 1e-12)
            case "learningRateFinal":
                config.td3.learningRateFinal = max(value, 0.0)
            case "learningRateDecayRate":
                config.td3.learningRateDecayRate = max(value, 1e-6)
            case "learningRateMinValue":
                config.td3.learningRateMinValue = max(value, 0.0)
            case "learningRateGamma":
                config.td3.learningRateGamma = max(value, 1e-6)
            case "warmupInitialValue":
                config.td3.warmupInitialValue = max(value, 0.0)
            case "targetPolicyNoise":
                config.td3.targetPolicyNoise = max(value, 0.0)
            case "targetNoiseClip":
                config.td3.targetNoiseClip = max(value, 0.0)
            case "actionNoiseStd":
                config.td3.actionNoiseStd = max(value, 0.0)
            case "ouTheta":
                config.td3.ouTheta = max(value, 0.0)
            case "ouDt":
                config.td3.ouDt = max(value, 1e-9)
            case "ouInitialNoise":
                config.td3.ouInitialNoise = value
            case "optimizerActorBeta1":
                config.td3.optimizerActorBeta1 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerActorBeta2":
                config.td3.optimizerActorBeta2 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerActorEps":
                config.td3.optimizerActorEps = max(value, 1e-12)
            case "optimizerCriticBeta1":
                config.td3.optimizerCriticBeta1 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerCriticBeta2":
                config.td3.optimizerCriticBeta2 = clamp(value, min: 0.0, max: 0.999_999)
            case "optimizerCriticEps":
                config.td3.optimizerCriticEps = max(value, 1e-12)
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
            case "batchSize":
                config.dqn.batchSize = max(1, value)
            case "bufferSize":
                config.dqn.bufferSize = max(1, value)
            case "learningStarts":
                config.dqn.learningStarts = max(0, value)
            case "targetUpdateInterval":
                config.dqn.targetUpdateInterval = max(1, value)
            case "trainFrequency":
                config.dqn.trainFrequency = max(1, value)
            case "gradientSteps":
                config.dqn.gradientSteps = max(1, value)
            default: break
            }
        case .ppo:
            switch id {
            case "nSteps":
                config.ppo.nSteps = max(1, value)
            case "batchSize":
                config.ppo.batchSize = max(1, value)
            case "nEpochs":
                config.ppo.nEpochs = max(1, value)
            case "sdeSampleFreq":
                config.ppo.sdeSampleFreq = value < 0 ? -1 : value
            default: break
            }
        case .sac:
            switch id {
            case "batchSize":
                config.sac.batchSize = max(1, value)
            case "bufferSize":
                config.sac.bufferSize = max(1, value)
            case "learningStarts":
                config.sac.learningStarts = max(0, value)
            case "targetUpdateInterval":
                config.sac.targetUpdateInterval = max(1, value)
            case "gradientSteps":
                config.sac.gradientSteps = max(1, value)
            case "trainFrequency":
                config.sac.trainFrequency = max(1, value)
            case "sdeSampleFreq":
                config.sac.sdeSampleFreq = value < 0 ? -1 : value
            case "nCritics":
                config.sac.nCritics = max(1, value)
            default: break
            }
        case .td3:
            switch id {
            case "batchSize":
                config.td3.batchSize = max(1, value)
            case "bufferSize":
                config.td3.bufferSize = max(1, value)
            case "learningStarts":
                config.td3.learningStarts = max(0, value)
            case "gradientSteps":
                config.td3.gradientSteps = max(1, value)
            case "trainFrequency":
                config.td3.trainFrequency = max(1, value)
            case "policyDelay":
                config.td3.policyDelay = max(1, value)
            case "nCritics":
                config.td3.nCritics = max(1, value)
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
            case "optimizeMemoryUsage":
                config.dqn.optimizeMemoryUsage = value
                if value {
                    config.dqn.handleTimeoutTermination = false
                }
            case "handleTimeoutTermination":
                config.dqn.handleTimeoutTermination = value
                if value {
                    config.dqn.optimizeMemoryUsage = false
                }
            case "normalizeImages": config.dqn.normalizeImages = value
            case "warmupEnabled": config.dqn.warmupEnabled = value
            default: break
            }
        case .ppo:
            switch id {
            case "clipRangeVfEnabled": config.ppo.clipRangeVfEnabled = value
            case "normalizeAdvantage": config.ppo.normalizeAdvantage = value
            case "targetKLEnabled": config.ppo.targetKLEnabled = value
            case "useSDE":
                config.ppo.useSDE = value
                if !value {
                    config.ppo.sdeSampleFreq = -1
                }
            case "normalizeImages": config.ppo.normalizeImages = value
            case "shareFeaturesExtractor": config.ppo.shareFeaturesExtractor = value
            case "orthoInit": config.ppo.orthoInit = value
            case "fullStd": config.ppo.fullStd = value
            case "warmupEnabled": config.ppo.warmupEnabled = value
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
            case "optimizeMemoryUsage":
                config.sac.optimizeMemoryUsage = value
                if value {
                    config.sac.handleTimeoutTermination = false
                }
            case "handleTimeoutTermination":
                config.sac.handleTimeoutTermination = value
                if value {
                    config.sac.optimizeMemoryUsage = false
                }
            case "warmupEnabled": config.sac.warmupEnabled = value
            default: break
            }
        case .td3:
            switch id {
            case "shareFeaturesExtractor": config.td3.shareFeaturesExtractor = value
            case "normalizeImages": config.td3.normalizeImages = value
            case "optimizeMemoryUsage":
                config.td3.optimizeMemoryUsage = value
                if value {
                    config.td3.handleTimeoutTermination = false
                }
            case "handleTimeoutTermination":
                config.td3.handleTimeoutTermination = value
                if value {
                    config.td3.optimizeMemoryUsage = false
                }
            case "warmupEnabled": config.td3.warmupEnabled = value
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
                let normalized = normalizedGradientStepsMode(raw: trimmed)
                if normalized == .fixed, config.dqn.gradientSteps < 1 {
                    config.dqn.gradientSteps = 1
                }
                config.dqn.gradientStepsMode = normalized
            default:
                break
            }
        case .ppo:
            switch id {
            case "netArch":
                let parsed = parseIntList(trimmed)
                if !parsed.isEmpty { config.ppo.netArch = parsed }
            case "learningRateSchedule":
                if ["constant", "linear", "exponential", "step", "cosine"].contains(trimmed) {
                    config.ppo.learningRateSchedule = trimmed
                }
            case "learningRateMilestones":
                config.ppo.learningRateMilestones = trimmed
            case "activation":
                if ["tanh", "relu"].contains(trimmed.lowercased()) {
                    config.ppo.activation = trimmed.lowercased()
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
                let normalized = normalizedGradientStepsMode(raw: trimmed)
                if normalized == .fixed, config.sac.gradientSteps < 1 {
                    config.sac.gradientSteps = 1
                }
                config.sac.gradientStepsMode = normalized
            case "criticActivation":
                config.sac.criticActivation = trimmed
            default:
                break
            }
        case .td3:
            switch id {
            case "netArch":
                let parsed = parseIntList(trimmed)
                if !parsed.isEmpty { config.td3.netArch = parsed }
            case "learningRateSchedule":
                if ["constant", "linear", "exponential", "step", "cosine"].contains(trimmed) {
                    config.td3.learningRateSchedule = trimmed
                }
            case "learningRateMilestones":
                config.td3.learningRateMilestones = trimmed
            case "activation":
                config.td3.activation = trimmed
            case "trainFrequencyUnit":
                if ["step", "episode"].contains(trimmed) {
                    config.td3.trainFrequencyUnit = trimmed
                }
            case "gradientStepsMode":
                let normalized = normalizedGradientStepsMode(raw: trimmed)
                if normalized == .fixed, config.td3.gradientSteps < 1 {
                    config.td3.gradientSteps = 1
                }
                config.td3.gradientStepsMode = normalized
            case "actionNoiseType":
                if ["none", "normal", "ou"].contains(trimmed) {
                    config.td3.actionNoiseType = trimmed
                }
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

    private static func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
        min(max(value, minValue), maxValue)
    }

    private func normalizedGradientStepsMode(
        mode: GradientStepsMode,
        count: Int
    ) -> GradientStepsMode {
        if count < 0 {
            return .asCollectedSteps
        }
        return mode
    }

    private static func normalizedGradientStepsMode(raw: String) -> GradientStepsMode {
        GradientStepsMode(rawString: raw)
    }
}

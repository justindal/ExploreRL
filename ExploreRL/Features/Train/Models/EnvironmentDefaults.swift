//
//  EnvironmentDefaults.swift
//  ExploreRL
//

import Foundation

enum EnvironmentDefaults {

    static func config(for envID: String) -> TrainingConfig {
        switch envID {
        case "CartPole":
            return cartPole
        case "MountainCar":
            return mountainCar
        case "Acrobot":
            return acrobot
        case "LunarLander":
            return lunarLander
        case "CarRacingDiscrete":
            return carRacingDiscrete
        case "Pendulum":
            return pendulum
        case "MountainCarContinuous":
            return mountainCarContinuous
        case "LunarLanderContinuous":
            return lunarLanderContinuous
        case "CarRacing":
            return carRacing
        default:
            return TrainingConfig()
        }
    }

    static func totalTimestepsDefault(for envID: String, algorithm: AlgorithmType) -> Int {
        switch envID {
        case "CartPole":
            switch algorithm {
            case .dqn: return 50_000
            case .ppo: return 100_000
            default: return 50_000
            }
        case "MountainCar":
            switch algorithm {
            case .dqn: return 120_000
            case .ppo: return 1_000_000
            default: return 120_000
            }
        case "Acrobot":
            switch algorithm {
            case .dqn: return 100_000
            case .ppo: return 1_000_000
            default: return 100_000
            }
        case "LunarLander":
            switch algorithm {
            case .dqn: return 100_000
            case .ppo: return 1_000_000
            default: return 100_000
            }
        case "CarRacingDiscrete":
            switch algorithm {
            case .dqn: return 100_000
            case .ppo: return 100_000
            default: return 100_000
            }
        case "Pendulum":
            switch algorithm {
            case .ppo: return 100_000
            case .sac, .td3: return 20_000
            default: return 20_000
            }
        case "MountainCarContinuous":
            switch algorithm {
            case .ppo: return 20_000
            case .sac: return 50_000
            case .td3: return 300_000
            default: return 50_000
            }
        case "LunarLanderContinuous":
            switch algorithm {
            case .ppo: return 1_000_000
            case .sac: return 500_000
            case .td3: return 300_000
            default: return 500_000
            }
        case "CarRacing":
            switch algorithm {
            case .ppo: return 4_000_000
            case .sac, .td3: return 1_000_000
            default: return 1_000_000
            }
        default:
            return TrainingConfig().totalTimesteps
        }
    }
}

extension EnvironmentDefaults {

    private static var cartPole: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .dqn
        c.totalTimesteps = 50_000
        c.dqn.learningRate = 2.3e-3
        c.dqn.batchSize = 64
        c.dqn.bufferSize = 100_000
        c.dqn.learningStarts = 1_000
        c.dqn.gamma = 0.99
        c.dqn.targetUpdateInterval = 10
        c.dqn.trainFrequency = 256
        c.dqn.gradientSteps = 128
        c.dqn.explorationFraction = 0.16
        c.dqn.explorationFinalEps = 0.04
        c.dqn.netArch = [256, 256]
        c.ppo.learningRate = 1e-3
        c.ppo.learningRateSchedule = "linear"
        c.ppo.learningRateFinal = 0.0
        c.ppo.nSteps = 32
        c.ppo.batchSize = 256
        c.ppo.nEpochs = 20
        c.ppo.gamma = 0.98
        c.ppo.gaeLambda = 0.8
        c.ppo.clipRange = 0.2
        c.ppo.entCoef = 0.0
        return c
    }

    private static var mountainCar: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .dqn
        c.totalTimesteps = 120_000
        c.dqn.learningRate = 4e-3
        c.dqn.batchSize = 128
        c.dqn.bufferSize = 10_000
        c.dqn.learningStarts = 1_000
        c.dqn.gamma = 0.98
        c.dqn.targetUpdateInterval = 600
        c.dqn.trainFrequency = 16
        c.dqn.gradientSteps = 8
        c.dqn.explorationFraction = 0.2
        c.dqn.explorationFinalEps = 0.07
        c.dqn.netArch = [256, 256]
        c.ppo.nSteps = 16
        c.ppo.nEpochs = 4
        c.ppo.gamma = 0.99
        c.ppo.gaeLambda = 0.98
        c.ppo.entCoef = 0.0
        return c
    }

    private static var acrobot: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .dqn
        c.totalTimesteps = 100_000
        c.dqn.learningRate = 6.3e-4
        c.dqn.batchSize = 128
        c.dqn.bufferSize = 50_000
        c.dqn.learningStarts = 0
        c.dqn.gamma = 0.99
        c.dqn.targetUpdateInterval = 250
        c.dqn.trainFrequency = 4
        c.dqn.gradientSteps = -1
        c.dqn.gradientStepsMode = .asCollectedSteps
        c.dqn.explorationFraction = 0.12
        c.dqn.explorationFinalEps = 0.1
        c.dqn.netArch = [256, 256]
        c.ppo.nSteps = 256
        c.ppo.nEpochs = 4
        c.ppo.gamma = 0.99
        c.ppo.gaeLambda = 0.94
        c.ppo.entCoef = 0.0
        return c
    }

    private static var lunarLander: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .dqn
        c.totalTimesteps = 100_000
        c.dqn.learningRate = 6.3e-4
        c.dqn.batchSize = 128
        c.dqn.bufferSize = 50_000
        c.dqn.learningStarts = 0
        c.dqn.gamma = 0.99
        c.dqn.targetUpdateInterval = 250
        c.dqn.trainFrequency = 4
        c.dqn.gradientSteps = -1
        c.dqn.gradientStepsMode = .asCollectedSteps
        c.dqn.explorationFraction = 0.12
        c.dqn.explorationFinalEps = 0.1
        c.dqn.netArch = [256, 256]
        c.ppo.nSteps = 1024
        c.ppo.batchSize = 64
        c.ppo.nEpochs = 4
        c.ppo.gamma = 0.999
        c.ppo.gaeLambda = 0.98
        c.ppo.entCoef = 0.01
        return c
    }

    private static var carRacingDiscrete: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .dqn
        c.totalTimesteps = 100_000
        c.dqn.learningRate = 1e-4
        c.dqn.batchSize = 64
        c.dqn.bufferSize = 100_000
        c.dqn.learningStarts = 1_000
        c.dqn.gamma = 0.99
        c.dqn.targetUpdateInterval = 250
        c.dqn.trainFrequency = 4
        c.dqn.gradientSteps = -1
        c.dqn.gradientStepsMode = .asCollectedSteps
        c.dqn.explorationFraction = 0.2
        c.dqn.explorationFinalEps = 0.05
        return c
    }
}

extension EnvironmentDefaults {

    private static var pendulum: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .sac
        c.totalTimesteps = 100_000
        c.sac.learningRate = 1e-3
        c.td3.learningRate = 1e-3
        c.td3.gamma = 0.98
        c.td3.bufferSize = 200_000
        c.td3.learningStarts = 10_000
        c.td3.actionNoiseType = "normal"
        c.td3.actionNoiseStd = 0.1
        c.td3.gradientSteps = 1
        c.td3.trainFrequency = 1
        c.td3.netArch = [400, 300]
        c.ppo.learningRate = 1e-3
        c.ppo.nSteps = 1024
        c.ppo.nEpochs = 10
        c.ppo.gamma = 0.9
        c.ppo.gaeLambda = 0.95
        c.ppo.clipRange = 0.2
        c.ppo.entCoef = 0.0
        c.ppo.useSDE = true
        c.ppo.sdeSampleFreq = 4
        return c
    }

    private static var mountainCarContinuous: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .sac
        c.totalTimesteps = 50_000
        c.sac.learningRate = 3e-4
        c.sac.bufferSize = 50_000
        c.sac.batchSize = 512
        c.sac.gamma = 0.9999
        c.sac.tau = 0.01
        c.sac.trainFrequency = 32
        c.sac.gradientSteps = 32
        c.sac.learningStarts = 0
        c.sac.autoEntropyTuning = false
        c.sac.fixedEntCoef = 0.1
        c.sac.useSDE = true
        c.sac.logStdInit = -3.67
        c.sac.netArch = [64, 64]
        c.td3.learningRate = 1e-3
        c.td3.actionNoiseType = "ou"
        c.td3.actionNoiseStd = 0.5
        c.td3.gradientSteps = 1
        c.td3.trainFrequency = 1
        c.td3.batchSize = 256
        c.td3.netArch = [400, 300]
        c.ppo.learningRate = 7.77e-05
        c.ppo.nSteps = 8
        c.ppo.batchSize = 256
        c.ppo.nEpochs = 10
        c.ppo.gamma = 0.9999
        c.ppo.gaeLambda = 0.9
        c.ppo.clipRange = 0.1
        c.ppo.entCoef = 0.00429
        c.ppo.vfCoef = 0.19
        c.ppo.maxGradNorm = 5.0
        c.ppo.useSDE = true
        c.ppo.logStdInit = -3.29
        c.ppo.orthoInit = false
        return c
    }

    private static var lunarLanderContinuous: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .sac
        c.totalTimesteps = 500_000
        c.sac.learningRate = 7.3e-4
        c.sac.learningRateSchedule = "linear"
        c.sac.learningRateFinal = 0.0
        c.sac.batchSize = 256
        c.sac.bufferSize = 1_000_000
        c.sac.gamma = 0.99
        c.sac.tau = 0.01
        c.sac.trainFrequency = 1
        c.sac.gradientSteps = 1
        c.sac.learningStarts = 10_000
        c.sac.netArch = [400, 300]
        c.td3.learningRate = 1e-3
        c.td3.gamma = 0.98
        c.td3.bufferSize = 200_000
        c.td3.learningStarts = 10_000
        c.td3.actionNoiseType = "normal"
        c.td3.actionNoiseStd = 0.1
        c.td3.gradientSteps = 1
        c.td3.trainFrequency = 1
        c.td3.netArch = [400, 300]
        c.ppo.nSteps = 1024
        c.ppo.batchSize = 64
        c.ppo.nEpochs = 4
        c.ppo.gamma = 0.999
        c.ppo.gaeLambda = 0.98
        c.ppo.entCoef = 0.01
        return c
    }

    private static var carRacing: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .sac
        c.totalTimesteps = 1_000_000
        c.sac.learningRate = 7.3e-4
        c.sac.bufferSize = 300_000
        c.sac.batchSize = 256
        c.sac.gamma = 0.99
        c.sac.tau = 0.02
        c.sac.trainFrequency = 8
        c.sac.gradientSteps = 10
        c.sac.learningStarts = 1_000
        c.sac.useSDE = true
        c.sac.useSDEAtWarmup = true
        c.ppo.learningRate = 1e-4
        c.ppo.learningRateSchedule = "linear"
        c.ppo.learningRateFinal = 0.0
        c.ppo.nSteps = 512
        c.ppo.batchSize = 128
        c.ppo.nEpochs = 10
        c.ppo.gamma = 0.99
        c.ppo.gaeLambda = 0.95
        c.ppo.clipRange = 0.2
        c.ppo.entCoef = 0.0
        c.ppo.vfCoef = 0.5
        c.ppo.maxGradNorm = 0.5
        c.ppo.useSDE = true
        c.ppo.sdeSampleFreq = 4
        c.ppo.activation = "relu"
        c.ppo.netArch = [256]
        c.ppo.orthoInit = false
        c.ppo.logStdInit = -2.0
        return c
    }
}

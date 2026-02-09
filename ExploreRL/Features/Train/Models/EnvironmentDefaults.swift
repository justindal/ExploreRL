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
}

// MARK: - DQN

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
        c.dqn.gradientStepsMode = "asCollectedSteps"
        c.dqn.explorationFraction = 0.12
        c.dqn.explorationFinalEps = 0.1
        c.dqn.netArch = [256, 256]
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
        c.dqn.gradientStepsMode = "asCollectedSteps"
        c.dqn.explorationFraction = 0.12
        c.dqn.explorationFinalEps = 0.1
        c.dqn.netArch = [256, 256]
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
        c.dqn.gradientStepsMode = "asCollectedSteps"
        c.dqn.explorationFraction = 0.2
        c.dqn.explorationFinalEps = 0.05
        return c
    }
}

// MARK: - SAC

extension EnvironmentDefaults {

    private static var pendulum: TrainingConfig {
        var c = TrainingConfig()
        c.algorithm = .sac
        c.totalTimesteps = 20_000
        c.sac.learningRate = 1e-3
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
        return c
    }
}

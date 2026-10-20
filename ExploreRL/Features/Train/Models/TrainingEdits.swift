import Foundation

enum TrainingEdits {
    static func editableIDs(for algorithm: AlgorithmType) -> Set<String> {
        let schedule: Set<String> = [
            "learningRate", "learningRateSchedule", "learningRateFinal", "learningRateDecayRate",
            "learningRateMinValue", "learningRateMilestones", "learningRateGamma", "warmupEnabled",
            "warmupFraction", "warmupInitialValue",
        ]
        switch algorithm {
        case .qLearning, .sarsa:
            return ["learningRate", "gamma", "epsilonDecay", "minEpsilon"]
        case .ppo:
            return schedule.union([
                "nSteps", "batchSize", "nEpochs", "gamma", "gaeLambda", "clipRange",
                "clipRangeVfEnabled", "clipRangeVf", "normalizeAdvantage", "entCoef", "vfCoef",
                "maxGradNorm", "targetKLEnabled", "targetKL",
            ])
        case .dqn:
            return schedule.union([
                "batchSize", "gamma", "tau", "trainFrequency", "trainFrequencyUnit",
                "gradientStepsMode", "gradientSteps", "targetUpdateInterval", "learningStarts",
                "explorationFraction", "explorationFinalEps", "maxGradNorm",
            ])
        case .sac, .td3:
            return schedule.union([
                "batchSize", "gamma", "tau", "trainFrequency", "trainFrequencyUnit",
                "gradientStepsMode", "gradientSteps", "learningStarts", "targetUpdateInterval",
            ])
        }
    }

    static func validate(_ proposed: TrainingConfig, replacing original: TrainingConfig, steps: Int) throws {
        guard proposed.totalTimesteps >= max(1, steps), proposed.totalTimesteps <= 1_000_000_000 else {
            throw TrainError.invalidConfiguration("The step target must cover the steps already trained and be at most one billion.")
        }
        var allowed = original
        allowed.totalTimesteps = proposed.totalTimesteps
        allowed.renderDuringTraining = proposed.renderDuringTraining
        allowed.renderFPS = proposed.renderFPS
        let accessor = HyperparameterAccessor(config: proposed)
        for definition in HyperparameterConfig.definitions(for: original.algorithm)
        where editableIDs(for: original.algorithm).contains(definition.id) {
            switch definition.type {
            case .double:
                HyperparameterAccessor.setDouble(id: definition.id, value: accessor.doubleValue(for: definition.id), on: &allowed)
            case .float:
                HyperparameterAccessor.setFloat(id: definition.id, value: accessor.floatValue(for: definition.id), on: &allowed)
            case .int:
                HyperparameterAccessor.setInt(id: definition.id, value: accessor.intValue(for: definition.id), on: &allowed)
            case .bool:
                HyperparameterAccessor.setBool(id: definition.id, value: accessor.boolValue(for: definition.id), on: &allowed)
            case .string:
                HyperparameterAccessor.setString(id: definition.id, value: accessor.stringValue(for: definition.id), on: &allowed)
            }
        }
        guard allowed == proposed else {
            throw TrainError.invalidConfiguration("Changing the algorithm, seed, network, optimizer or replay layout requires a new run.")
        }
    }

    static func requiresReload(_ proposed: TrainingConfig, replacing original: TrainingConfig) -> Bool {
        var controlsOnly = original
        controlsOnly.totalTimesteps = proposed.totalTimesteps
        controlsOnly.renderDuringTraining = proposed.renderDuringTraining
        controlsOnly.renderFPS = proposed.renderFPS
        return controlsOnly != proposed
    }
}

import Foundation
import Gymnazo

extension TrainViewModel {
    func applyContinuationConfig(_ proposed: TrainingConfig, for id: String) async throws {
        guard canSnapshot(id), let env = env(for: id) else {
            throw TrainError.invalidConfiguration("Pause training and wait for it to stop before applying changes.")
        }
        let original = trainingConfig(for: id)
        try TrainingEdits.validate(proposed, replacing: original, steps: trainingState(for: id).currentTimestep)
        if TrainingEdits.requiresReload(proposed, replacing: original) {
            let snapshot = try await makeSnapshot(for: id)
            snapshottingEnvs.insert(id)
            defer {
                snapshottingEnvs.remove(id)
                SessionStorage.shared.discard(snapshot)
            }
            switch proposed.algorithm {
            case .qLearning, .sarsa:
                let algorithmEnv = try await makeAlgorithmEnv(for: id)
                let config = TabularConfig(
                    learningRate: proposed.tabular.learningRate, gamma: proposed.tabular.gamma,
                    epsilon: proposed.tabular.epsilon, epsilonDecay: proposed.tabular.epsilonDecay,
                    minEpsilon: proposed.tabular.minEpsilon
                )
                tabularAgents[id] = try TabularAgent.load(from: snapshot.checkpointDirectory, env: algorithmEnv, config: config)
            case .dqn:
                _ = try await dqnAlgorithm(for: id, env: env, config: proposed, restoringFrom: snapshot.checkpointDirectory)
            case .ppo:
                _ = try await ppoAlgorithm(for: id, env: env, config: proposed, restoringFrom: snapshot.checkpointDirectory)
            case .sac:
                _ = try await sacAlgorithm(for: id, env: env, config: proposed, restoringFrom: snapshot.checkpointDirectory)
            case .td3:
                _ = try await td3Algorithm(for: id, env: env, config: proposed, restoringFrom: snapshot.checkpointDirectory)
            }
        }
        trainingConfigs[id] = proposed
        updateTrainingState(for: id) {
            $0.status = $0.currentTimestep >= proposed.totalTimesteps ? .completed : .paused
            $0.statusMessage = nil
        }
    }

    func extendTraining(for id: String, additionalTimesteps: Int) throws {
        guard canSnapshot(id), trainingPolicy(for: id).isAllowed else {
            throw TrainError.invalidConfiguration("Wait for the current training operation to finish.")
        }
        let current = trainingState(for: id).currentTimestep
        guard additionalTimesteps > 0, additionalTimesteps <= 1_000_000_000 - current else {
            throw TrainError.invalidConfiguration("Enter a positive additional step count within the one-billion-step limit.")
        }
        var config = trainingConfig(for: id)
        config.totalTimesteps = current + additionalTimesteps
        trainingConfigs[id] = config
        updateTrainingState(for: id) { $0.status = .paused }
        startTraining(for: id)
    }

    func timedTrainingSteps(for id: String) -> Int {
        max(0, trainingState(for: id).currentTimestep - (trainingTimings[id]?.initialTimestep ?? trainingState(for: id).currentTimestep))
    }
}

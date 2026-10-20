//
//  TrainViewModel+Persistence.swift
//  ExploreRL
//

import Foundation
import Gymnazo

extension TrainViewModel {

    func saveSession(for id: String, name: String) async throws {
        let snapshot = try await makeSnapshot(for: id)
        defer { SessionStorage.shared.discard(snapshot) }
        _ = try SessionStorage.shared.saveSnapshot(snapshot, name: name)
    }

    func canSnapshot(_ id: String) -> Bool {
        trainingTasks[id] == nil && !snapshottingEnvs.contains(id) && !resettingEnvs.contains(id)
            && trainingState(for: id).status != .training && trainingState(for: id).currentTimestep > 0
            && hasAlgorithm(for: id)
    }

    func hasAlgorithm(for id: String) -> Bool {
        switch trainingConfig(for: id).algorithm {
        case .qLearning, .sarsa: tabularAgents[id] != nil
        case .dqn: dqnAlgorithms[id] != nil
        case .ppo: ppoAlgorithms[id] != nil
        case .sac: sacAlgorithms[id] != nil
        case .td3: td3Algorithms[id] != nil
        }
    }

    func makeSnapshot(for id: String) async throws -> TrainingSnapshot {
        guard canSnapshot(id), isTrainingActive else {
            throw TrainError.invalidConfiguration("Wait for training to stop before creating a checkpoint.")
        }
        snapshottingEnvs.insert(id)
        defer { snapshottingEnvs.remove(id) }
        flushAccumulator(for: id)
        let config = trainingConfig(for: id)
        let session = SavedSession(
            id: UUID(), name: "Current run", environmentID: id, algorithmType: config.algorithm,
            trainingConfig: config, trainingState: trainingState(for: id), envSettings: settings(for: id),
            savedAt: .now,
            observationVersion: id == MetroRunnerSettings.id ? MetroRunnerObservation.version : nil,
            activeTrainingSeconds: activeTrainingElapsed(for: id), timingStartTimestep: trainingTimings[id]?.initialTimestep
        )
        let snapshot = TrainingSnapshot(session: session, directory: SessionStorage.shared.snapshotDirectory(for: session.id))
        do {
            switch config.algorithm {
            case .qLearning, .sarsa: try await tabularAgents[id]?.save(to: snapshot.checkpointDirectory)
            case .dqn: try await dqnAlgorithms[id]?.save(to: snapshot.checkpointDirectory)
            case .ppo: try await ppoAlgorithms[id]?.save(to: snapshot.checkpointDirectory)
            case .sac: try await sacAlgorithms[id]?.save(to: snapshot.checkpointDirectory)
            case .td3: try await td3Algorithms[id]?.save(to: snapshot.checkpointDirectory)
            }
            try Task.checkCancellation()
            return snapshot
        } catch {
            SessionStorage.shared.discard(snapshot)
            throw error
        }
    }

    @MainActor
    func loadSession(_ session: SavedSession) async throws {
        try SessionCompatibility.validate(session)
        let id = session.environmentID

        guard !snapshottingEnvs.contains(id), !resettingEnvs.contains(id) else {
            throw TrainError.invalidConfiguration("Wait for the current session operation to finish.")
        }
        snapshottingEnvs.insert(id)
        defer { snapshottingEnvs.remove(id) }
        let task = trainingTasks[id]
        task?.cancel()
        await task?.value
        stopFlushLoop(for: id)
        accumulators[id] = nil
        trainingTimings[id] = nil
        trainingPhases[id] = nil
        trainingTasks[id] = nil
        tabularAgents[id] = nil
        dqnAlgorithms[id] = nil
        ppoAlgorithms[id] = nil
        sacAlgorithms[id] = nil
        td3Algorithms[id] = nil
        renderSnapshots[id] = nil

        envSettings[id] = session.envSettings
        trainingConfigs[id] = session.trainingConfig

        await createEnv(id: id)

        let checkpointDir = SessionStorage.shared.checkpointDirectory(for: session.id)

        guard env(for: id) != nil else {
            throw TrainError.environmentNotLoaded
        }

        switch session.algorithmType {
        case .qLearning, .sarsa:
            let algorithmEnv = try await makeAlgorithmEnv(for: id)
            tabularAgents[id] = try TabularAgent.load(from: checkpointDir, env: algorithmEnv)
        case .dqn:
            let algorithmEnv = try await makeAlgorithmEnv(for: id)
            dqnAlgorithms[id] = try await DQN.load(from: checkpointDir, env: algorithmEnv)
        case .ppo:
            let algorithmEnv = try await makeAlgorithmEnv(for: id)
            ppoAlgorithms[id] = try await PPO.load(from: checkpointDir, env: algorithmEnv)
        case .sac:
            let algorithmEnv = try await makeAlgorithmEnv(for: id)
            sacAlgorithms[id] = try await SAC.load(from: checkpointDir, env: algorithmEnv)
        case .td3:
            let algorithmEnv = try await makeAlgorithmEnv(for: id)
            td3Algorithms[id] = try await TD3.load(from: checkpointDir, env: algorithmEnv)
        }

        var restoredState = session.trainingState
        restoredState.status = restoredState.currentTimestep >= session.trainingConfig.totalTimesteps ? .completed : .paused
        trainingTimings[id] = TrainingTiming(
            startedAt: .now,
            initialTimestep: session.timingStartTimestep ?? restoredState.currentTimestep,
            previousElapsed: session.activeTrainingSeconds ?? 0
        )
        trainingTimings[id]?.pause(at: .now)
        trainingStates[id] = restoredState
    }
}

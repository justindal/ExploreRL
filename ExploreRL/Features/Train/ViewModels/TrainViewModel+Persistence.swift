//
//  TrainViewModel+Persistence.swift
//  ExploreRL
//

import Foundation
import Gymnazo

extension TrainViewModel {

    func saveSession(for id: String, name: String) async throws {
        let config = trainingConfig(for: id)
        let state = trainingState(for: id)
        let settings = envSettings[id] ?? [:]

        let hasAlgorithm: Bool = {
            switch config.algorithm {
            case .qLearning, .sarsa: return tabularAgents[id] != nil
            case .dqn: return dqnAlgorithms[id] != nil
            case .ppo: return ppoAlgorithms[id] != nil
            case .sac: return sacAlgorithms[id] != nil
            case .td3: return td3Algorithms[id] != nil
            }
        }()

        guard hasAlgorithm else { throw TrainError.noAlgorithmToSave }

        let session = SavedSession(
            id: UUID(),
            name: name,
            environmentID: id,
            algorithmType: config.algorithm,
            trainingConfig: config,
            trainingState: state,
            envSettings: settings,
            savedAt: Date()
        )

        let storage = SessionStorage.shared
        try storage.save(session: session)

        let checkpointDir = storage.checkpointDirectory(for: session.id)

        switch config.algorithm {
        case .qLearning, .sarsa:
            if let agent = tabularAgents[id] {
                try await agent.save(to: checkpointDir)
            }
        case .dqn:
            if let dqn = dqnAlgorithms[id] {
                try await dqn.save(to: checkpointDir)
            }
        case .ppo:
            if let ppo = ppoAlgorithms[id] {
                try await ppo.save(to: checkpointDir)
            }
        case .sac:
            if let sac = sacAlgorithms[id] {
                try await sac.save(to: checkpointDir)
            }
        case .td3:
            if let td3 = td3Algorithms[id] {
                try await td3.save(to: checkpointDir)
            }
        }
    }

    @MainActor
    func loadSession(_ session: SavedSession) async throws {
        let id = session.environmentID

        trainingTasks[id]?.cancel()
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

        guard let env = env(for: id) else {
            throw TrainError.environmentNotLoaded
        }

        switch session.algorithmType {
        case .qLearning, .sarsa:
            tabularAgents[id] = try TabularAgent.load(from: checkpointDir, env: env)
        case .dqn:
            dqnAlgorithms[id] = try DQN.load(from: checkpointDir, env: env)
        case .ppo:
            ppoAlgorithms[id] = try PPO.load(from: checkpointDir, env: env)
        case .sac:
            sacAlgorithms[id] = try SAC.load(from: checkpointDir, env: env)
        case .td3:
            td3Algorithms[id] = try TD3.load(from: checkpointDir, env: env)
        }

        var restoredState = session.trainingState
        restoredState.status = .paused
        trainingStates[id] = restoredState
    }
}

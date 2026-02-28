//
//  AlgorithmType.swift
//  ExploreRL
//

import Foundation

enum AlgorithmType: String, CaseIterable, Identifiable, Codable {
    case qLearning = "Q-Learning"
    case sarsa = "SARSA"
    case dqn = "DQN"
    case ppo = "PPO"
    case sac = "SAC"
    case td3 = "TD3"

    var id: String { rawValue }

    var isTabular: Bool {
        switch self {
        case .qLearning, .sarsa:
            return true
        case .dqn, .ppo, .sac, .td3:
            return false
        }
    }

    var requiresDiscreteActions: Bool {
        switch self {
        case .qLearning, .sarsa, .dqn:
            return true
        case .ppo, .sac, .td3:
            return false
        }
    }

    var requiresContinuousActions: Bool {
        switch self {
        case .sac, .td3:
            return true
        default:
            return false
        }
    }

    var requiresDiscreteObservations: Bool {
        isTabular
    }
}

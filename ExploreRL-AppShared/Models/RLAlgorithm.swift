//
//  RLAlgorithm.swift
//

import Foundation

enum RLAlgorithm: String, CaseIterable, Identifiable {
    case qLearning = "Q-Learning"
    case sarsa = "SARSA"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .qLearning:
            return "Off-policy algorithm that learns the value of the optimal policy independently of the agent's actions."
        case .sarsa:
            return "On-policy algorithm (State-Action-Reward-State-Action) that learns the value of the policy being followed."
        }
    }
    
    var defaults: (learningRate: Float, gamma: Float, epsilon: Float, epsilonDecay: Float) {
        switch self {
        case .qLearning:
            return (learningRate: 0.8, gamma: 0.95, epsilon: 1.0, epsilonDecay: 0.995)
        case .sarsa:
            return (learningRate: 0.5, gamma: 0.99, epsilon: 1.0, epsilonDecay: 0.999)
        }
    }
}


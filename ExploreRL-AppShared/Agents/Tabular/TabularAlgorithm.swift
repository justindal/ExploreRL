//
//  TabularAlgorithm.swift
//  ExploreRL
//
//  Algorithm selection for tabular RL methods (discrete state/action spaces)
//

import Foundation

/// Available tabular reinforcement learning algorithms
public enum TabularAlgorithm: String, CaseIterable, Identifiable {
    case qLearning = "Q-Learning"
    case sarsa = "SARSA"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .qLearning:
            return "Off-policy algorithm that learns the value of the optimal policy independently of the agent's actions."
        case .sarsa:
            return "On-policy algorithm (State-Action-Reward-State-Action) that learns the value of the policy being followed."
        }
    }
    
    /// Default hyperparameters for each algorithm
    public struct Defaults {
        public let learningRate: Float
        public let gamma: Float
        public let epsilon: Float
        public let epsilonDecay: Float
    }
    
    public var defaults: Defaults {
        switch self {
        case .qLearning:
            return Defaults(learningRate: 0.8, gamma: 0.95, epsilon: 1.0, epsilonDecay: 0.995)
        case .sarsa:
            return Defaults(learningRate: 0.5, gamma: 0.99, epsilon: 1.0, epsilonDecay: 0.999)
        }
    }
}


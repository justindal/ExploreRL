//
//  MetricCard.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-08.
//

import Foundation

enum EnvKind: String, Sendable, CaseIterable, Identifiable {
    case toyText
    case classicControl
    case box2D

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toyText: "Toy Text"
        case .classicControl: "Classic Control"
        case .box2D: "Box2D"
        }
    }
}

enum ExploreSection: String, CaseIterable, Identifiable {
    case reinforcementLearning
    case algorithms
    case environments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reinforcementLearning: "Reinforcement Learning"
        case .algorithms: "Algorithms"
        case .environments: "Environments"
        }
    }

    var items: [ExploreItem] {
        switch self {
        case .reinforcementLearning: [.rlLoop, .returns, .exploration, .replay, .neuralNetworks, .activationFunctions, .optimizers]
        case .algorithms: [.qLearning, .sarsa, .dqn, .sac]
        case .environments: [.frozenLake, .blackjack, .taxi, .cliffWalking, .cartPole, .mountainCar, .acrobot, .pendulum, .lunarLander, .carRacing]
        }
    }
}

enum ExploreItem: String, CaseIterable, Identifiable, Hashable {
    case rlLoop
    case returns
    case exploration
    case replay
    case neuralNetworks
    case activationFunctions
    case optimizers

    case qLearning
    case sarsa
    case dqn
    case sac

    case frozenLake
    case blackjack
    case taxi
    case cliffWalking
    case cartPole
    case mountainCar
    case acrobot
    case pendulum
    case lunarLander
    case carRacing

    var id: String { rawValue }

    var environmentKind: EnvKind? {
        switch self {
        case .frozenLake, .blackjack, .taxi, .cliffWalking:
            .toyText
        case .cartPole, .mountainCar, .acrobot, .pendulum:
            .classicControl
        case .lunarLander, .carRacing:
            .box2D
        default:
            nil
        }
    }

    var suggestedAlgorithms: [String] {
        switch self {
        case .frozenLake, .cliffWalking:
            ["Q‑Learning", "SARSA"]
        case .blackjack, .taxi:
            ["Q‑Learning"]
        case .cartPole:
            ["DQN"]
        case .mountainCar, .acrobot:
            ["DQN", "SAC"]
        case .pendulum:
            ["SAC"]
        case .lunarLander:
            ["DQN", "SAC"]
        case .carRacing:
            ["DQN", "SAC"]
        default:
            []
        }
    }

    var title: String {
        switch self {
        case .rlLoop: "The RL Loop"
        case .returns: "Returns & Discounting"
        case .exploration: "Exploration vs Exploitation"
        case .replay: "Experience Replay"
        case .neuralNetworks: "Neural Networks"
        case .activationFunctions: "Activation Functions"
        case .optimizers: "Optimizers"
        case .qLearning: "Q‑Learning"
        case .sarsa: "SARSA"
        case .dqn: "DQN"
        case .sac: "SAC"
        case .frozenLake: "Frozen Lake"
        case .blackjack: "Blackjack"
        case .taxi: "Taxi"
        case .cliffWalking: "Cliff Walking"
        case .cartPole: "Cart Pole"
        case .mountainCar: "Mountain Car"
        case .acrobot: "Acrobot"
        case .pendulum: "Pendulum"
        case .lunarLander: "Lunar Lander"
        case .carRacing: "Car Racing"
        }
    }

    var subtitle: String {
        switch self {
        case .rlLoop: "Observation, action, reward"
        case .returns: "Gamma and cumulative reward"
        case .exploration: "Balancing learning and exploiting"
        case .replay: "Learning from stored transitions"
        case .neuralNetworks: "Function approximation and learning"
        case .activationFunctions: "Non-linearity in neural networks"
        case .optimizers: "Gradient-based weight updates"
        case .qLearning: "Off-policy tabular method"
        case .sarsa: "On-policy tabular method"
        case .dqn: "Deep Q-Network"
        case .sac: "Soft Actor-Critic"
        case .frozenLake: "Navigate a grid without falling in holes"
        case .blackjack: "Beat the dealer without going over 21"
        case .taxi: "Pick up and drop off passengers"
        case .cliffWalking: "Find the safe path along a cliff"
        case .cartPole: "Balance a pole on a moving cart"
        case .mountainCar: "Build momentum to reach the goal"
        case .acrobot: "Swing a double pendulum upward"
        case .pendulum: "Swing up and balance"
        case .lunarLander: "Land a spacecraft safely"
        case .carRacing: "Drive around a procedural track"
        }
    }
}

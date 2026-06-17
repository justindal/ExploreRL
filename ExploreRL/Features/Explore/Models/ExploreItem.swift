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
        case .reinforcementLearning:
            [
                .rlLoop, .multiArmedBandits, .returns, .dynamicProgramming, .monteCarlo,
                .exploration, .replay, .neuralNetworks, .activationFunctions, .optimizers,
            ]
        case .algorithms:
            [.qLearning, .sarsa, .policyGradient, .dqn, .ddpg, .ppo, .sac, .td3, .a2c]
        case .environments:
            [
                .frozenLake, .blackjack, .taxi, .cliffWalking, .cartPole, .mountainCar, .acrobot,
                .pendulum, .lunarLander, .carRacing,
            ]
        }
    }
}

enum ExploreItem: String, CaseIterable, Identifiable, Hashable {
    case rlLoop
    case multiArmedBandits
    case returns
    case dynamicProgramming
    case monteCarlo
    case exploration
    case replay
    case neuralNetworks
    case activationFunctions
    case optimizers

    case qLearning
    case sarsa
    case policyGradient
    case dqn
    case ddpg
    case ppo
    case sac
    case td3
    case a2c

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
            ["Q-Learning", "SARSA"]
        case .blackjack, .taxi:
            ["Q-Learning"]
        case .cartPole:
            ["DQN", "PPO"]
        case .mountainCar, .acrobot:
            ["DQN", "PPO", "SAC"]
        case .pendulum:
            ["PPO", "SAC", "TD3"]
        case .lunarLander:
            ["DQN", "PPO", "SAC", "TD3"]
        case .carRacing:
            ["DQN", "PPO", "SAC", "TD3"]
        default:
            []
        }
    }

    var relatedItems: [ExploreItem] {
        switch self {
        case .rlLoop: [.returns, .exploration, .qLearning]
        case .multiArmedBandits: [.exploration, .qLearning]
        case .returns: [.rlLoop, .monteCarlo, .qLearning]
        case .dynamicProgramming: [.returns, .qLearning, .monteCarlo]
        case .monteCarlo: [.returns, .dynamicProgramming, .qLearning]
        case .exploration: [.multiArmedBandits, .rlLoop, .qLearning]
        case .replay: [.dqn, .sac, .td3]
        case .neuralNetworks: [.activationFunctions, .optimizers, .dqn]
        case .activationFunctions: [.neuralNetworks, .optimizers]
        case .optimizers: [.neuralNetworks, .activationFunctions]
        case .qLearning: [.sarsa, .dqn, .rlLoop]
        case .sarsa: [.qLearning, .cliffWalking, .rlLoop]
        case .policyGradient: [.ppo, .a2c, .returns]
        case .dqn: [.qLearning, .ddpg, .replay]
        case .ddpg: [.dqn, .td3, .sac]
        case .ppo: [.policyGradient, .a2c, .sac]
        case .sac: [.td3, .ddpg, .ppo]
        case .td3: [.ddpg, .sac, .dqn]
        case .a2c: [.policyGradient, .ppo, .returns]
        case .frozenLake: [.qLearning, .sarsa, .cliffWalking]
        case .blackjack: [.qLearning, .monteCarlo]
        case .taxi: [.qLearning, .frozenLake]
        case .cliffWalking: [.sarsa, .qLearning, .frozenLake]
        case .cartPole: [.dqn, .ppo, .mountainCar]
        case .mountainCar: [.dqn, .sac, .cartPole]
        case .acrobot: [.dqn, .sac, .pendulum]
        case .pendulum: [.sac, .td3, .acrobot]
        case .lunarLander: [.dqn, .sac, .carRacing]
        case .carRacing: [.dqn, .ppo, .lunarLander]
        }
    }

    var title: String {
        switch self {
        case .rlLoop: "The RL Loop"
        case .multiArmedBandits: "Multi-Armed Bandits"
        case .returns: "Returns & Discounting"
        case .dynamicProgramming: "Dynamic Programming"
        case .monteCarlo: "Monte Carlo Methods"
        case .exploration: "Exploration vs Exploitation"
        case .replay: "Experience Replay"
        case .neuralNetworks: "Neural Networks"
        case .activationFunctions: "Activation Functions"
        case .optimizers: "Optimizers"
        case .qLearning: "Q-Learning"
        case .sarsa: "SARSA"
        case .policyGradient: "Policy Gradient"
        case .dqn: "DQN"
        case .ddpg: "DDPG"
        case .ppo: "PPO"
        case .sac: "SAC"
        case .td3: "TD3"
        case .a2c: "A2C"
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
        case .multiArmedBandits: "The simplest explore-exploit problem"
        case .returns: "Gamma and cumulative reward"
        case .dynamicProgramming: "Policy iteration and value iteration"
        case .monteCarlo: "Learning from complete episodes"
        case .exploration: "Balancing learning and exploiting"
        case .replay: "Learning from stored transitions"
        case .neuralNetworks: "Function approximation and learning"
        case .activationFunctions: "Non-linearity in neural networks"
        case .optimizers: "Gradient-based weight updates"
        case .qLearning: "Off-policy tabular method"
        case .sarsa: "On-policy tabular method"
        case .policyGradient: "Directly optimize the policy"
        case .dqn: "Deep Q-Network"
        case .ddpg: "Deep Deterministic Policy Gradient"
        case .ppo: "Proximal Policy Optimization"
        case .sac: "Soft Actor-Critic"
        case .td3: "Twin Delayed DDPG"
        case .a2c: "Advantage Actor-Critic"
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

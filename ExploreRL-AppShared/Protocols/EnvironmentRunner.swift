//
//  EnvironmentRunner.swift
//

import SwiftUI
import Foundation

/// Base protocol for all environment runners
@MainActor
protocol EnvironmentRunner: AnyObject, Observable {
    associatedtype SnapshotType
    
    var snapshot: SnapshotType? { get }
    var episodeCount: Int { get }
    var currentStep: Int { get }
    var episodeReward: Double { get }
    var isTraining: Bool { get }
    var renderEnabled: Bool { get set }
    var episodeMetrics: [EpisodeMetrics] { get }
    var episodesPerRun: Int { get set }
    var targetFPS: Double { get set }
    
    var totalEpisodesTrained: Int { get }
    
    var isWarmingUp: Bool { get }
    var warmupProgress: Double { get }
    
    func startTraining()
    func stopTraining()
    func reset()
    func setupEnvironment()
    
    static var environmentType: EnvironmentType { get }
    static var displayName: String { get }
    static var algorithmName: String { get }
    static var icon: String { get }
    static var accentColor: Color { get }
    static var category: EnvironmentCategory { get }
}

/// Protocol for environments that support saving and loading agents
@MainActor
protocol SavableEnvironmentRunner: EnvironmentRunner {
    var loadedAgentId: UUID? { get }
    var loadedAgentName: String? { get }
    var hasTrainedSinceLoad: Bool { get }
    var canResume: Bool { get }
    var totalEpisodesTrained: Int { get }
    var averageReward: Double { get }
    
    var totalTrainingTimeSeconds: TimeInterval { get }
    
    var accumulatedTrainingTimeSeconds: TimeInterval { get }
    
    var trainingSessionStartDate: Date? { get }
    
    func saveAgent(name: String) throws
    func loadAgent(from agent: SavedAgent) throws
    func updateAgent(id: UUID, name: String) throws
}

enum EnvironmentCategory: String, CaseIterable, Identifiable {
    case toyText = "Toy Text"
    case classicControl = "Classic Control"
    case box2d = "Box2D"
    case atari = "Atari"
    case mujoco = "MuJoCo"
    
    var id: String { rawValue }
}

enum EnvironmentType: String, Codable, CaseIterable, Identifiable {
    case frozenLake = "FrozenLake"
    case blackjack = "Blackjack"
    case taxi = "Taxi"
    case cliffWalking = "CliffWalking"
    case cartPole = "CartPole"
    case mountainCar = "MountainCar"
    case mountainCarContinuous = "MountainCarContinuous"
    case acrobot = "Acrobot"
    case pendulum = "Pendulum"
    case lunarLander = "LunarLander"
    case lunarLanderContinuous = "LunarLanderContinuous"
    case carRacing = "CarRacing"
    case carRacingDiscrete = "CarRacingDiscrete"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .frozenLake: return "Frozen Lake"
        case .blackjack: return "Blackjack"
        case .taxi: return "Taxi"
        case .cliffWalking: return "Cliff Walking"
        case .cartPole: return "Cart Pole"
        case .mountainCar: return "Mountain Car"
        case .mountainCarContinuous: return "Mountain Car Continuous"
        case .acrobot: return "Acrobot"
        case .pendulum: return "Pendulum"
        case .lunarLander: return "Lunar Lander"
        case .lunarLanderContinuous: return "Lunar Lander Continuous"
        case .carRacing: return "Car Racing"
        case .carRacingDiscrete: return "Car Racing Discrete"
        }
    }
    
    var iconName: String {
        switch self {
        case .frozenLake: return "snowflake"
        case .blackjack: return "suit.spade.fill"
        case .taxi: return "car.fill"
        case .cliffWalking: return "arrow.triangle.turn.up.right.diamond"
        case .cartPole: return "cart"
        case .mountainCar: return "car.side"
        case .mountainCarContinuous: return "car.side.fill"
        case .acrobot: return "figure.flexibility"
        case .pendulum: return "circle.circle"
        case .lunarLander: return "airplane"
        case .lunarLanderContinuous: return "airplane.circle.fill"
        case .carRacing: return "flag.checkered"
        case .carRacingDiscrete: return "flag.checkered.circle.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .frozenLake: return .cyan
        case .blackjack: return .mint
        case .taxi: return .yellow
        case .cliffWalking: return .brown
        case .cartPole: return .orange
        case .mountainCar: return .green
        case .mountainCarContinuous: return .purple
        case .lunarLander: return .blue
        case .lunarLanderContinuous: return .teal
        case .acrobot: return .red
        case .pendulum: return .indigo
        case .carRacing: return .pink
        case .carRacingDiscrete: return .gray
        }
    }
    
    var category: EnvironmentCategory {
        switch self {
        case .frozenLake, .blackjack, .taxi, .cliffWalking: return .toyText
        case .cartPole, .mountainCar, .mountainCarContinuous, .acrobot, .pendulum: return .classicControl
        case .lunarLander, .lunarLanderContinuous, .carRacing, .carRacingDiscrete: return .box2d
        }
    }
    
    var defaultAlgorithm: String {
        switch self {
        case .frozenLake, .blackjack, .taxi, .cliffWalking: return "Q-Learning"
        case .cartPole, .mountainCar, .acrobot, .lunarLander, .carRacingDiscrete: return "DQN"
        case .mountainCarContinuous, .pendulum, .lunarLanderContinuous, .carRacing: return "SAC"
        }
    }
}


extension EnvironmentRunner {
    var runProgress: Double {
        guard episodesPerRun > 0 else { return 0 }
        return Double(episodeMetrics.count) / Double(episodesPerRun)
    }
    
    var isWarmingUp: Bool { false }
    var warmupProgress: Double { 1.0 }
}

extension SavableEnvironmentRunner {
    var hasUnsavedChanges: Bool {
        episodeMetrics.count > 0 && (loadedAgentId == nil || hasTrainedSinceLoad)
    }
}

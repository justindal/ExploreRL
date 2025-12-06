//
//  EnvironmentRegistry.swift
//
//  Central registry for all available environments.
//  Provides metadata and factory methods for dynamic environment listing.
//

import SwiftUI

/// Environment metadata for UI display and navigation
struct EnvironmentInfo: Identifiable {
    let type: EnvironmentType
    let displayName: String
    let algorithmName: String
    let icon: String
    let accentColor: Color
    let category: EnvironmentCategory
    let description: String
    
    var id: String { type.rawValue }
}

/// Central registry for all available environments
struct EnvironmentRegistry {
    /// All registered environments with their metadata
    static let environments: [EnvironmentInfo] = [
        // Toy Text
        EnvironmentInfo(
            type: .frozenLake,
            displayName: "Frozen Lake",
            algorithmName: "Q-Learning / SARSA",
            icon: "snowflake",
            accentColor: .cyan,
            category: .toyText,
            description: "Navigate a frozen lake from start to goal without falling into holes."
        ),
        
        // Classic Control
        EnvironmentInfo(
            type: .cartPole,
            displayName: "Cart Pole",
            algorithmName: "DQN",
            icon: "cart",
            accentColor: .orange,
            category: .classicControl,
            description: "Balance a pole on a moving cart by applying left or right forces."
        ),
        EnvironmentInfo(
            type: .mountainCar,
            displayName: "Mountain Car",
            algorithmName: "DQN",
            icon: "car.side",
            accentColor: .green,
            category: .classicControl,
            description: "Drive a car up a steep hill using momentum."
        ),
        EnvironmentInfo(
            type: .mountainCarContinuous,
            displayName: "Mountain Car Continuous",
            algorithmName: "SAC",
            icon: "car.side.fill",
            accentColor: .purple,
            category: .classicControl,
            description: "Drive a car up a steep hill with continuous force control."
        ),
        EnvironmentInfo(
            type: .acrobot,
            displayName: "Acrobot",
            algorithmName: "DQN",
            icon: "figure.flexibility",
            accentColor: .red,
            category: .classicControl,
            description: "Swing a two-link robot arm to reach a target height."
        ),
        EnvironmentInfo(
            type: .pendulum,
            displayName: "Pendulum",
            algorithmName: "SAC",
            icon: "circle.circle",
            accentColor: .indigo,
            category: .classicControl,
            description: "Swing up and balance an inverted pendulum using continuous torque."
        ),
        
        // Box2D
        EnvironmentInfo(
            type: .lunarLander,
            displayName: "Lunar Lander",
            algorithmName: "DQN",
            icon: "airplane",
            accentColor: .blue,
            category: .box2d,
            description: "Land a rocket on the moon by controlling main and side thrusters."
        ),
        EnvironmentInfo(
            type: .lunarLanderContinuous,
            displayName: "Lunar Lander Continuous",
            algorithmName: "SAC",
            icon: "airplane.circle.fill",
            accentColor: .teal,
            category: .box2d,
            description: "Land a rocket with continuous throttle control for main and side engines."
        )
    ]
    
    /// Get all environments in a specific category
    static func environments(in category: EnvironmentCategory) -> [EnvironmentInfo] {
        environments.filter { $0.category == category }
    }
    
    /// Get environment info by type
    static func info(for type: EnvironmentType) -> EnvironmentInfo? {
        environments.first { $0.type == type }
    }
    
    /// All categories that have at least one environment
    static var activeCategories: [EnvironmentCategory] {
        let categoriesWithEnvironments = Set(environments.map { $0.category })
        return EnvironmentCategory.allCases.filter { categoriesWithEnvironments.contains($0) }
    }
    
    /// Grouped environments by category
    static var groupedEnvironments: [(category: EnvironmentCategory, environments: [EnvironmentInfo])] {
        activeCategories.map { category in
            (category, environments(in: category))
        }
    }
}


extension EnvironmentRegistry {
    /// Creates a navigation destination view for the given environment type
    @MainActor @ViewBuilder
    static func destinationView(
        for type: EnvironmentType,
        frozenLakeRunner: FrozenLakeRunner,
        cartPoleRunner: CartPoleRunner,
        mountainCarRunner: MountainCarRunner,
        mountainCarContinuousRunner: MountainCarContinuousRunner,
        acrobotRunner: AcrobotRunner,
        pendulumRunner: PendulumRunner,
        lunarLanderRunner: LunarLanderRunner,
        lunarLanderContinuousRunner: LunarLanderContinuousRunner
    ) -> some View {
        switch type {
        case .frozenLake:
            FrozenLakeView(runner: frozenLakeRunner)
        case .cartPole:
            CartPoleView(runner: cartPoleRunner)
        case .mountainCar:
            MountainCarView(runner: mountainCarRunner)
        case .mountainCarContinuous:
            MountainCarContinuousView(runner: mountainCarContinuousRunner)
        case .acrobot:
            AcrobotView(runner: acrobotRunner)
        case .pendulum:
            PendulumView(runner: pendulumRunner)
        case .lunarLander:
            LunarLanderView(runner: lunarLanderRunner)
        case .lunarLanderContinuous:
            LunarLanderContinuousView(runner: lunarLanderContinuousRunner)
        }
    }
}


//
//  EnvironmentInfoTabModels.swift
//

import SwiftUI

enum EnvironmentInfoTabModels {
    private static func overview(for type: EnvironmentType) -> String? {
        EnvironmentRegistry.info(for: type)?.description
    }
    
    private static func truncationLine(maxStepsPerEpisode: Int?) -> String {
        if let maxStepsPerEpisode {
            return "Truncation: episode ends after \(maxStepsPerEpisode) steps (Max Steps / Ep setting)."
        }
        return "Truncation: controlled by Max Steps / Ep setting."
    }
    
    static func cartPole(maxStepsPerEpisode: Int?) -> EnvironmentInfoTabModel {
        EnvironmentInfoTabModel(
            title: "Cart Pole — Info",
            subtitle: "Classic control • Discrete actions",
            overview: overview(for: .cartPole),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(4,)"),
                        .init(label: "Observation", value: "[x, ẋ, θ, θ̇]"),
                        .init(label: "Action Space", value: "Discrete(2)")
                    ])
                ),
                .init(
                    title: "Actions",
                    kind: .keyValues([
                        .init(label: "0", value: "Push cart left"),
                        .init(label: "1", value: "Push cart right")
                    ])
                ),
                .init(
                    title: "Rewards",
                    kind: .bullets([
                        "Reward: +1 for each step the pole stays balanced."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: |θ| > 12° or |x| > 2.4.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func mountainCar(maxStepsPerEpisode: Int?) -> EnvironmentInfoTabModel {
        EnvironmentInfoTabModel(
            title: "Mountain Car — Info",
            subtitle: "Classic control • Discrete actions",
            overview: overview(for: .mountainCar),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(2,)"),
                        .init(label: "Observation", value: "[position, velocity]"),
                        .init(label: "Position Range", value: "[-1.2, 0.6]"),
                        .init(label: "Velocity Range", value: "[-0.07, 0.07]"),
                        .init(label: "Action Space", value: "Discrete(3)")
                    ])
                ),
                .init(
                    title: "Actions",
                    kind: .keyValues([
                        .init(label: "0", value: "Push left"),
                        .init(label: "1", value: "No push"),
                        .init(label: "2", value: "Push right")
                    ])
                ),
                .init(
                    title: "Rewards & goal",
                    kind: .bullets([
                        "Reward: −1 per step.",
                        "Goal: reach position ≥ 0.5."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: goal reached.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func mountainCarContinuous(maxStepsPerEpisode: Int?) -> EnvironmentInfoTabModel {
        EnvironmentInfoTabModel(
            title: "Mountain Car Continuous — Info",
            subtitle: "Classic control • Continuous actions",
            overview: overview(for: .mountainCarContinuous),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(2,)"),
                        .init(label: "Observation", value: "[position, velocity]"),
                        .init(label: "Position Range", value: "[-1.2, 0.6]"),
                        .init(label: "Velocity Range", value: "[-0.07, 0.07]"),
                        .init(label: "Action Space", value: "Box(1,)"),
                        .init(label: "Action Range", value: "[-1, 1]")
                    ])
                ),
                .init(
                    title: "Rewards & goal",
                    kind: .bullets([
                        "Goal: reach position ≥ 0.45.",
                        "Reward: large bonus at goal with a small action penalty."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: goal reached.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func acrobot(maxStepsPerEpisode: Int?) -> EnvironmentInfoTabModel {
        EnvironmentInfoTabModel(
            title: "Acrobot — Info",
            subtitle: "Classic control • Discrete actions",
            overview: overview(for: .acrobot),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(6,)"),
                        .init(label: "Observation", value: "[cos(θ₁), sin(θ₁), cos(θ₂), sin(θ₂), θ̇₁, θ̇₂]"),
                        .init(label: "Action Space", value: "Discrete(3)")
                    ])
                ),
                .init(
                    title: "Actions",
                    kind: .keyValues([
                        .init(label: "0", value: "−1 torque"),
                        .init(label: "1", value: "0 torque"),
                        .init(label: "2", value: "+1 torque")
                    ])
                ),
                .init(
                    title: "Rewards & goal",
                    kind: .bullets([
                        "Reward: −1 each step until success; 0 on success.",
                        "Goal: swing the end-effector above the target height."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: goal reached.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func pendulum(maxStepsPerEpisode: Int?) -> EnvironmentInfoTabModel {
        EnvironmentInfoTabModel(
            title: "Pendulum — Info",
            subtitle: "Classic control • Continuous actions",
            overview: overview(for: .pendulum),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(3,)"),
                        .init(label: "Observation", value: "[cos(θ), sin(θ), θ̇]"),
                        .init(label: "Action Space", value: "Box(1,)"),
                        .init(label: "Action Range", value: "[-2.0, 2.0] torque")
                    ])
                ),
                .init(
                    title: "Rewards & goal",
                    kind: .bullets([
                        "Goal: keep the pendulum upright (θ ≈ 0).",
                        "Reward: −(θ² + 0.1θ̇² + 0.001τ²)."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: none (typically).",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func lunarLander(maxStepsPerEpisode: Int?) -> EnvironmentInfoTabModel {
        EnvironmentInfoTabModel(
            title: "Lunar Lander — Info",
            subtitle: "Box2D • Discrete actions",
            overview: overview(for: .lunarLander),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(8,)"),
                        .init(label: "Observation", value: "[x, y, vx, vy, θ, ω, leg_l, leg_r]"),
                        .init(label: "Action Space", value: "Discrete(4)")
                    ])
                ),
                .init(
                    title: "Actions",
                    kind: .keyValues([
                        .init(label: "0", value: "No-op"),
                        .init(label: "1", value: "Fire left engine"),
                        .init(label: "2", value: "Fire main engine"),
                        .init(label: "3", value: "Fire right engine")
                    ])
                ),
                .init(
                    title: "Rewards",
                    kind: .bullets([
                        "Reward shaping encourages safe landing with low velocity and upright angle.",
                        "Typical successful returns are positive (often ~100–140)."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: crash or successful land.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func lunarLanderContinuous(maxStepsPerEpisode: Int?) -> EnvironmentInfoTabModel {
        EnvironmentInfoTabModel(
            title: "Lunar Lander Continuous — Info",
            subtitle: "Box2D • Continuous actions",
            overview: overview(for: .lunarLanderContinuous),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(8,)"),
                        .init(label: "Observation", value: "[x, y, vx, vy, θ, ω, leg_l, leg_r]"),
                        .init(label: "Action Space", value: "Box(2,)"),
                        .init(label: "Actions", value: "[main_engine, lateral]")
                    ])
                ),
                .init(
                    title: "Rewards",
                    kind: .bullets([
                        "Reward shaping encourages soft landing, centered position, and stable legs contact.",
                        "Typical successful returns are positive (often ~100–140)."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: crash or successful land.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func frozenLake(
        algorithmName: String?,
        mapName: String?,
        customMapSize: Int?,
        isSlippery: Bool?,
        maxStepsPerEpisode: Int?
    ) -> EnvironmentInfoTabModel {
        let resolvedMapSize: String = {
            guard let mapName else { return "Unknown" }
            switch mapName {
            case "4x4": return "4×4"
            case "8x8": return "8×8"
            case "Custom":
                if let customMapSize { return "\(customMapSize)×\(customMapSize)" }
                return "Custom"
            default:
                return mapName
            }
        }()
        
        let slipperyLine: String = (isSlippery ?? false) ? "Dynamics: stochastic (slippery)." : "Dynamics: deterministic."
        
        return EnvironmentInfoTabModel(
            title: "Frozen Lake — Info",
            subtitle: "Toy text • Discrete actions" + (algorithmName.map { " • \($0)" } ?? ""),
            overview: overview(for: .frozenLake),
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Map", value: resolvedMapSize),
                        .init(label: "State Space", value: "Discrete(N)"),
                        .init(label: "Action Space", value: "Discrete(4)"),
                        .init(label: "Actions", value: "←(0) ↓(1) →(2) ↑(3)")
                    ])
                ),
                .init(
                    title: "Rewards",
                    kind: .bullets([
                        "Goal: +1.0",
                        "Hole: 0.0",
                        "Step: 0.0"
                    ])
                ),
                .init(
                    title: "Dynamics",
                    kind: .bullets([
                        slipperyLine
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: reach the goal or fall into a hole.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func cliffWalking(
        algorithmName: String?,
        isSlippery: Bool?,
        maxStepsPerEpisode: Int?
    ) -> EnvironmentInfoTabModel {
        let slipperyLine: String = (isSlippery ?? false) ? "Slippery surface: stochastic movement." : "Normal surface: deterministic movement."
        
        return EnvironmentInfoTabModel(
            title: "Cliff Walking — Info",
            subtitle: "Toy text • Discrete actions" + (algorithmName.map { " • \($0)" } ?? ""),
            overview: EnvironmentRegistry.info(for: .cliffWalking)?.description,
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "State Space", value: "Discrete(48)"),
                        .init(label: "Grid", value: "4 rows × 12 columns"),
                        .init(label: "Action Space", value: "Discrete(4)")
                    ])
                ),
                .init(
                    title: "Actions",
                    kind: .keyValues([
                        .init(label: "0", value: "Up"),
                        .init(label: "1", value: "Right"),
                        .init(label: "2", value: "Down"),
                        .init(label: "3", value: "Left")
                    ])
                ),
                .init(
                    title: "Rewards",
                    kind: .bullets([
                        "Step: −1 (time penalty)",
                        "Fall off cliff: −100 (returns to start)"
                    ])
                ),
                .init(
                    title: "Environment",
                    kind: .bullets([
                        slipperyLine,
                        "Start: bottom-left [3, 0]",
                        "Goal: bottom-right [3, 11]",
                        "Cliff: bottom row [3, 1..10]"
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: agent reaches the goal.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func taxi(
        algorithmName: String?,
        isRainy: Bool?,
        ficklePassenger: Bool?,
        maxStepsPerEpisode: Int?
    ) -> EnvironmentInfoTabModel {
        let rainyLine: String = (isRainy ?? false) ? "Weather: rainy (stochastic movement)." : "Weather: dry (deterministic movement)."
        let fickleLine: String = (ficklePassenger ?? false) ? "Passenger: fickle (may change destination)." : "Passenger: normal."
        
        return EnvironmentInfoTabModel(
            title: "Taxi — Info",
            subtitle: "Toy text • Discrete actions" + (algorithmName.map { " • \($0)" } ?? ""),
            overview: EnvironmentRegistry.info(for: .taxi)?.description,
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "State Space", value: "Discrete(500)"),
                        .init(label: "State Encoding", value: "(taxiPos × passLoc × dest)"),
                        .init(label: "Action Space", value: "Discrete(6)")
                    ])
                ),
                .init(
                    title: "Actions",
                    kind: .keyValues([
                        .init(label: "0", value: "South"),
                        .init(label: "1", value: "North"),
                        .init(label: "2", value: "East"),
                        .init(label: "3", value: "West"),
                        .init(label: "4", value: "Pickup"),
                        .init(label: "5", value: "Dropoff")
                    ])
                ),
                .init(
                    title: "Rewards",
                    kind: .bullets([
                        "Step: −1 (time penalty)",
                        "Successful dropoff: +20",
                        "Illegal pickup/dropoff: −10"
                    ])
                ),
                .init(
                    title: "Environment",
                    kind: .bullets([
                        rainyLine,
                        fickleLine,
                        "Locations: R (Red), G (Green), Y (Yellow), B (Blue)"
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: passenger delivered to destination.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    static func blackjack(
        algorithmName: String?,
        natural: Bool?,
        sab: Bool?,
        maxStepsPerEpisode: Int?
    ) -> EnvironmentInfoTabModel {
        let naturalLine: String = (natural ?? false) ? "Natural bonus: +1.5 for natural blackjack." : "Natural bonus: disabled."
        let sabLine: String = (sab ?? false) ? "Rules: Sutton & Barto textbook." : "Rules: standard casino."
        
        return EnvironmentInfoTabModel(
            title: "Blackjack — Info",
            subtitle: "Toy text • Discrete actions" + (algorithmName.map { " • \($0)" } ?? ""),
            overview: EnvironmentRegistry.info(for: .blackjack)?.description,
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "State Space", value: "Discrete(704)"),
                        .init(label: "Observation", value: "(playerSum, dealerCard, usableAce)"),
                        .init(label: "Action Space", value: "Discrete(2)")
                    ])
                ),
                .init(
                    title: "Actions",
                    kind: .keyValues([
                        .init(label: "0", value: "Stick (stop taking cards)"),
                        .init(label: "1", value: "Hit (take another card)")
                    ])
                ),
                .init(
                    title: "Rewards",
                    kind: .bullets([
                        "Win: +1.0",
                        "Lose: −1.0",
                        "Draw: 0.0",
                        naturalLine
                    ])
                ),
                .init(
                    title: "Rules",
                    kind: .bullets([
                        sabLine,
                        "Dealer hits until sum ≥ 17.",
                        "Face cards = 10, Ace = 1 or 11."
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: player sticks or busts.",
                        truncationLine(maxStepsPerEpisode: maxStepsPerEpisode)
                    ])
                )
            ]
        )
    }
    
    // Static models for Learn hub (no runner state)
    static func forLearn(type: EnvironmentType) -> EnvironmentInfoTabModel {
        switch type {
        case .cartPole:
            return cartPole(maxStepsPerEpisode: nil)
        case .mountainCar:
            return mountainCar(maxStepsPerEpisode: nil)
        case .mountainCarContinuous:
            return mountainCarContinuous(maxStepsPerEpisode: nil)
        case .acrobot:
            return acrobot(maxStepsPerEpisode: nil)
        case .pendulum:
            return pendulum(maxStepsPerEpisode: nil)
        case .lunarLander:
            return lunarLander(maxStepsPerEpisode: nil)
        case .lunarLanderContinuous:
            return lunarLanderContinuous(maxStepsPerEpisode: nil)
        case .frozenLake:
            return frozenLake(
                algorithmName: nil,
                mapName: "4x4",
                customMapSize: nil,
                isSlippery: true,
                maxStepsPerEpisode: nil
            )
        case .blackjack:
            return blackjack(
                algorithmName: nil,
                natural: false,
                sab: false,
                maxStepsPerEpisode: nil
            )
        case .taxi:
            return taxi(
                algorithmName: nil,
                isRainy: false,
                ficklePassenger: false,
                maxStepsPerEpisode: nil
            )
        case .cliffWalking:
            return cliffWalking(
                algorithmName: nil,
                isSlippery: false,
                maxStepsPerEpisode: nil
            )
        }
    }
}



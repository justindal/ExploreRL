//
//  EnvSettingsConfig.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-04.
//

import Foundation

enum SettingValue: Equatable, Codable {
    case bool(Bool)
    case float(Float)
    case string(String)
    case int(Int)

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    var floatValue: Float? {
        if case .float(let v) = self { return v }
        return nil
    }

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    var displayString: String {
        switch self {
        case .bool(let b): b ? "Yes" : "No"
        case .float(let f): String(format: "%.4g", f)
        case .string(let s): s.isEmpty ? "-" : s
        case .int(let i): "\(i)"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bool(let v):
            try container.encode("bool", forKey: .type)
            try container.encode(v, forKey: .value)
        case .float(let v):
            try container.encode("float", forKey: .type)
            try container.encode(v, forKey: .value)
        case .string(let v):
            try container.encode("string", forKey: .type)
            try container.encode(v, forKey: .value)
        case .int(let v):
            try container.encode("int", forKey: .type)
            try container.encode(v, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "bool": self = .bool(try container.decode(Bool.self, forKey: .value))
        case "float": self = .float(try container.decode(Float.self, forKey: .value))
        case "string": self = .string(try container.decode(String.self, forKey: .value))
        case "int": self = .int(try container.decode(Int.self, forKey: .value))
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.type], debugDescription: "Unknown setting type: \(type)")
            )
        }
    }
}

struct SettingDefinition: Identifiable {
    let id: String
    let label: String
    let defaultValue: SettingValue
    let description: String?
    let range: ClosedRange<Float>?
    let options: [String]?

    init(
        id: String,
        label: String,
        defaultValue: SettingValue,
        description: String? = nil,
        range: ClosedRange<Float>? = nil,
        options: [String]? = nil
    ) {
        self.id = id
        self.label = label
        self.defaultValue = defaultValue
        self.description = description
        self.range = range
        self.options = options
    }
}

struct EnvSettingsConfig {
    static func settings(for envID: String) -> [SettingDefinition] {
        let baseName = envID.split(separator: "-").first.map(String.init) ?? envID
        let seedSetting = SettingDefinition(
            id: "seed",
            label: "Seed",
            defaultValue: .string(""),
            description: "Optional seed for deterministic resets"
        )

        switch baseName {
        case "FrozenLake", "FrozenLake8x8":
            let defaultSize = envID.contains("8x8") ? 8 : 4
            return [
                seedSetting,
                SettingDefinition(
                    id: "size",
                    label: "Grid Size",
                    defaultValue: .int(defaultSize),
                    description: "Size of the square grid (NxN)",
                    range: 4...12
                ),
                SettingDefinition(
                    id: "is_slippery",
                    label: "Slippery",
                    defaultValue: .bool(true),
                    description: "Ice is slippery, actions may not work as intended (makes learning harder)"
                ),
                SettingDefinition(
                    id: "success_rate",
                    label: "Success Rate",
                    defaultValue: .float(Float(1.0 / 3.0)),
                    description: "Probability of moving in intended direction when slippery",
                    range: 0.33...1.0
                ),
                SettingDefinition(
                    id: "hole_probability",
                    label: "Hole Probability",
                    defaultValue: .float(0.2),
                    description: "Probability of a tile being a hole for random maps",
                    range: 0.0...0.5
                ),
                SettingDefinition(
                    id: "custom_map",
                    label: "Custom Map",
                    defaultValue: .string(""),
                    description: "Comma or newline separated rows, e.g. SFFF,FHFH,FFFH,HFFG"
                )
            ]

        case "Taxi":
            return [
                seedSetting,
                SettingDefinition(
                    id: "is_rainy",
                    label: "Rainy Weather",
                    defaultValue: .bool(false),
                    description: "Adds stochastic movement"
                ),
                SettingDefinition(
                    id: "fickle_passenger",
                    label: "Fickle Passenger",
                    defaultValue: .bool(false),
                    description: "Passenger may change destination"
                )
            ]

        case "CliffWalking":
            return [
                seedSetting,
                SettingDefinition(
                    id: "is_slippery",
                    label: "Slippery",
                    defaultValue: .bool(false),
                    description: "Adds wind effect to movements"
                )
            ]

        case "Blackjack":
            return [
                seedSetting,
                SettingDefinition(
                    id: "natural",
                    label: "Natural Blackjack Bonus",
                    defaultValue: .bool(false),
                    description: "Natural blackjack pays 1.5x"
                ),
                SettingDefinition(
                    id: "sab",
                    label: "Sutton & Barto Rules",
                    defaultValue: .bool(false),
                    description: "Use Sutton & Barto textbook rules"
                )
            ]

        case "Pendulum":
            return [
                seedSetting,
                SettingDefinition(
                    id: "g",
                    label: "Gravity",
                    defaultValue: .float(10.0),
                    range: 1.0...20.0
                ),
                SettingDefinition(
                    id: "x_init",
                    label: "X Init Range",
                    defaultValue: .float(Float.pi),
                    description: "Initial angle range",
                    range: 0.0...(Float.pi * 2.0)
                ),
                SettingDefinition(
                    id: "y_init",
                    label: "Y Init Range",
                    defaultValue: .float(1.0),
                    description: "Initial angular velocity range",
                    range: 0.0...5.0
                )
            ]

        case "MountainCar", "MountainCarContinuous":
            return [
                seedSetting,
                SettingDefinition(
                    id: "goal_velocity",
                    label: "Goal Velocity",
                    defaultValue: .float(0.0),
                    description: "Minimum velocity at goal",
                    range: 0.0...0.1
                )
            ]

        case "Acrobot":
            return [
                seedSetting,
                SettingDefinition(
                    id: "torque_noise_max",
                    label: "Torque Noise",
                    defaultValue: .float(0.0),
                    description: "Maximum random torque noise",
                    range: 0.0...1.0
                ),
                SettingDefinition(
                    id: "low",
                    label: "Reset Low",
                    defaultValue: .float(-0.1),
                    description: "Lower bound for random initial state",
                    range: -1.0...0.0
                ),
                SettingDefinition(
                    id: "high",
                    label: "Reset High",
                    defaultValue: .float(0.1),
                    description: "Upper bound for random initial state",
                    range: 0.0...1.0
                )
            ]

        case "LunarLander", "LunarLanderContinuous":
            return [
                seedSetting,
                SettingDefinition(
                    id: "gravity",
                    label: "Gravity",
                    defaultValue: .float(-10.0),
                    range: -11.99...(-0.01)
                ),
                SettingDefinition(
                    id: "enable_wind",
                    label: "Enable Wind",
                    defaultValue: .bool(false)
                ),
                SettingDefinition(
                    id: "wind_power",
                    label: "Wind Power",
                    defaultValue: .float(15.0),
                    range: 0.0...30.0
                ),
                SettingDefinition(
                    id: "turbulence_power",
                    label: "Turbulence Power",
                    defaultValue: .float(1.5),
                    range: 0.0...5.0
                )
            ]

        case "CarRacing", "CarRacingDiscrete":
            return [
                seedSetting,
                SettingDefinition(
                    id: "lap_complete_percent",
                    label: "Lap Complete %",
                    defaultValue: .float(0.95),
                    description: "Percentage of track needed to complete",
                    range: 0.5...1.0
                ),
                SettingDefinition(
                    id: "domain_randomize",
                    label: "Domain Randomization",
                    defaultValue: .bool(false),
                    description: "Randomize track colors"
                ),
                SettingDefinition(
                    id: "randomize",
                    label: "Randomize Colors",
                    defaultValue: .bool(true),
                    description: "Randomize colors on reset"
                )
            ]

        default:
            return [seedSetting]
        }
    }
}

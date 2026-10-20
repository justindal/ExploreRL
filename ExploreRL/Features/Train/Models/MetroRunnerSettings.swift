import Gymnazo

enum MetroRunnerSettings {
    static let id = "MetroRunner-v0"

    static var definitions: [SettingDefinition] {
        [
            SettingDefinition(id: "curriculum", label: "Curriculum", defaultValue: .string("full"),
                description: "Training subset of the supplied route layouts.",
                options: MetroRunnerCurriculum.allCases.map(\.rawValue)),
            SettingDefinition(id: "frame_skip", label: "Physics Ticks per Decision", defaultValue: .int(4),
                description: "One input followed by fixed 60 Hz physics ticks. Four ticks gives 15 decisions per second.",
                range: 1...12),
            SettingDefinition(id: "max_episode_seconds", label: "Episode Limit (seconds)", defaultValue: .int(300),
                description: "A surviving run ends at this time limit.", range: 10...600),
            SettingDefinition(id: "distance_scale", label: "Distance Reward", defaultValue: .float(0.01),
                description: "Reward per world unit travelled.", range: 0...0.05),
            SettingDefinition(id: "coin_weight", label: "Coin Reward", defaultValue: .float(0),
                description: "Additional reward per coin. Zero focuses the pilot on survival.", range: 0...1),
            SettingDefinition(id: "death_penalty", label: "Crash Penalty", defaultValue: .float(5), range: 0...20),
        ]
    }

    static func config(from settings: [String: SettingValue]) throws -> MetroRunnerConfig {
        let name = settings["curriculum"]?.stringValue ?? "full"
        guard let curriculum = MetroRunnerCurriculum(rawValue: name) else {
            throw TrainError.invalidConfiguration("Unknown Metro Run curriculum: \(name)")
        }
        return MetroRunnerConfig(
            curriculum: curriculum,
            frameSkip: settings["frame_skip"]?.intValue ?? 4,
            maxEpisodeSeconds: Double(settings["max_episode_seconds"]?.intValue ?? 300),
            reward: MetroRunnerReward(
                distanceScale: Double(settings["distance_scale"]?.floatValue ?? 0.01),
                coinWeight: Double(settings["coin_weight"]?.floatValue ?? 0),
                deathPenalty: Double(settings["death_penalty"]?.floatValue ?? 5)
            )
        )
    }
}

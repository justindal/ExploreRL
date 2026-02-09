//
//  TrainingConfig.swift
//  ExploreRL
//

import Foundation

struct TrainingConfig: Equatable, Codable {
    var algorithm: AlgorithmType = .qLearning
    var totalTimesteps: Int = 100_000
    var evalFrequency: Int = 5000
    var evalEpisodes: Int = 10
    var seed: String = ""
    var renderDuringTraining: Bool = true
    var renderFPS: Int = 60

    var tabular: TabularHyperparameters = TabularHyperparameters()
    var dqn: DQNHyperparameters = DQNHyperparameters()
    var sac: SACHyperparameters = SACHyperparameters()

    var seedValue: UInt64? {
        let trimmed = seed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return UInt64(trimmed)
    }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case algorithm
        case totalTimesteps
        case evalFrequency
        case evalEpisodes
        case seed
        case renderDuringTraining
        case renderFPS
        case tabular
        case dqn
        case sac
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case renderDelay
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        algorithm = try c.decodeIfPresent(AlgorithmType.self, forKey: .algorithm) ?? .qLearning
        totalTimesteps = try c.decodeIfPresent(Int.self, forKey: .totalTimesteps) ?? 100_000
        evalFrequency = try c.decodeIfPresent(Int.self, forKey: .evalFrequency) ?? 5000
        evalEpisodes = try c.decodeIfPresent(Int.self, forKey: .evalEpisodes) ?? 10
        seed = try c.decodeIfPresent(String.self, forKey: .seed) ?? ""
        renderDuringTraining =
            try c.decodeIfPresent(Bool.self, forKey: .renderDuringTraining) ?? true
        if let fps = try c.decodeIfPresent(Int.self, forKey: .renderFPS) {
            renderFPS = max(0, min(120, fps))
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            if let delay = try legacy.decodeIfPresent(Int.self, forKey: .renderDelay) {
                if delay <= 0 {
                    renderFPS = 0
                } else {
                    let fps = Int((1000.0 / Double(delay)).rounded())
                    renderFPS = max(1, min(120, fps))
                }
            } else {
                renderFPS = 60
            }
        }
        tabular =
            try c.decodeIfPresent(TabularHyperparameters.self, forKey: .tabular)
            ?? TabularHyperparameters()
        dqn = try c.decodeIfPresent(DQNHyperparameters.self, forKey: .dqn) ?? DQNHyperparameters()
        sac = try c.decodeIfPresent(SACHyperparameters.self, forKey: .sac) ?? SACHyperparameters()
    }
}

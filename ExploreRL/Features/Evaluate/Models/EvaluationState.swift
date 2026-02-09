//
//  EvaluationState.swift
//  ExploreRL
//

import Foundation

enum EvaluationStatus: Equatable {
    case idle
    case loading
    case running
    case completed
    case failed(String)
}

struct EvaluationState {
    var status: EvaluationStatus = .idle
    var currentEpisode: Int = 0
    var totalEpisodes: Int = 10
    var episodeRewards: [Double] = []
    var episodeLengths: [Int] = []
    var renderEnabled: Bool = true
    var renderFPS: Int = 60
    var renderVersion: Int = 0

    var meanReward: Double? {
        guard !episodeRewards.isEmpty else { return nil }
        return episodeRewards.reduce(0, +) / Double(episodeRewards.count)
    }

    var stdReward: Double? {
        guard episodeRewards.count > 1, let mean = meanReward else { return nil }
        let variance = episodeRewards.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
            / Double(episodeRewards.count)
        return variance.squareRoot()
    }

    var meanLength: Double? {
        guard !episodeLengths.isEmpty else { return nil }
        return Double(episodeLengths.reduce(0, +)) / Double(episodeLengths.count)
    }

    var stdLength: Double? {
        guard episodeLengths.count > 1, let mean = meanLength else { return nil }
        let variance = episodeLengths.reduce(0.0) { $0 + (Double($1) - mean) * (Double($1) - mean) }
            / Double(episodeLengths.count)
        return variance.squareRoot()
    }

    var progress: Double {
        guard totalEpisodes > 0 else { return 0 }
        return Double(currentEpisode) / Double(totalEpisodes)
    }

    mutating func reset() {
        status = .idle
        currentEpisode = 0
        episodeRewards = []
        episodeLengths = []
        renderVersion = 0
    }

    mutating func recordEpisode(reward: Double, length: Int) {
        episodeRewards.append(reward)
        episodeLengths.append(length)
        currentEpisode = episodeRewards.count
    }
}

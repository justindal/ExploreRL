//
//  TrainingState.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-04.
//

import Foundation

enum TrainingStatus: Equatable, Codable {
    case idle
    case training
    case paused
    case completed
    case failed(String)

    private enum CodingKeys: String, CodingKey {
        case type
        case message
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .idle:
            try container.encode("idle", forKey: .type)
        case .training:
            try container.encode("training", forKey: .type)
        case .paused:
            try container.encode("paused", forKey: .type)
        case .completed:
            try container.encode("completed", forKey: .type)
        case .failed(let msg):
            try container.encode("failed", forKey: .type)
            try container.encode(msg, forKey: .message)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "training": self = .training
        case "paused": self = .paused
        case "completed": self = .completed
        case "failed":
            let msg = try container.decode(String.self, forKey: .message)
            self = .failed(msg)
        default: self = .idle
        }
    }
}

struct TrainingState: Equatable, Codable {
    var status: TrainingStatus = .idle
    var currentTimestep: Int = 0
    var episodeCount: Int = 0
    var meanReward: Double?
    var meanEpisodeLength: Double?
    var explorationRate: Double?
    var rewardHistory: [Double] = []
    var episodeLengthHistory: [Double] = []
    var explorationRateHistory: [Double] = []
    var lossHistory: [Double] = []
    var tdErrorHistory: [Double] = []
    var qValueHistory: [Double] = []
    var learningRateHistory: [Double] = []
    var renderVersion: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decodeIfPresent(TrainingStatus.self, forKey: .status) ?? .idle
        currentTimestep = try c.decodeIfPresent(Int.self, forKey: .currentTimestep) ?? 0
        episodeCount = try c.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
        meanReward = try c.decodeIfPresent(Double.self, forKey: .meanReward)
        meanEpisodeLength = try c.decodeIfPresent(Double.self, forKey: .meanEpisodeLength)
        explorationRate = try c.decodeIfPresent(Double.self, forKey: .explorationRate)
        rewardHistory = try c.decodeIfPresent([Double].self, forKey: .rewardHistory) ?? []
        episodeLengthHistory = try c.decodeIfPresent([Double].self, forKey: .episodeLengthHistory) ?? []
        explorationRateHistory = try c.decodeIfPresent([Double].self, forKey: .explorationRateHistory) ?? []
        lossHistory = try c.decodeIfPresent([Double].self, forKey: .lossHistory) ?? []
        tdErrorHistory = try c.decodeIfPresent([Double].self, forKey: .tdErrorHistory) ?? []
        qValueHistory = try c.decodeIfPresent([Double].self, forKey: .qValueHistory) ?? []
        learningRateHistory = try c.decodeIfPresent([Double].self, forKey: .learningRateHistory) ?? []
        renderVersion = try c.decodeIfPresent(Int.self, forKey: .renderVersion) ?? 0
    }

    var isFailed: Bool {
        if case .failed = status { return true }
        return false
    }

    func progress(totalTimesteps: Int) -> Double {
        guard totalTimesteps > 0 else { return 0 }
        return Double(currentTimestep) / Double(totalTimesteps)
    }

    mutating func reset() {
        status = .idle
        currentTimestep = 0
        episodeCount = 0
        meanReward = nil
        meanEpisodeLength = nil
        explorationRate = nil
        rewardHistory = []
        episodeLengthHistory = []
        explorationRateHistory = []
        lossHistory = []
        tdErrorHistory = []
        qValueHistory = []
        learningRateHistory = []
        renderVersion = 0
    }

    mutating func recordEpisode(reward: Double, length: Int) {
        episodeCount += 1
        rewardHistory.append(reward)
        episodeLengthHistory.append(Double(length))

        if let rate = explorationRate {
            explorationRateHistory.append(rate)
        }

        let windowSize = min(100, rewardHistory.count)
        let recentRewards = rewardHistory.suffix(windowSize)
        let recentLengths = episodeLengthHistory.suffix(windowSize)

        meanReward = recentRewards.reduce(0, +) / Double(windowSize)
        meanEpisodeLength = recentLengths.reduce(0, +) / Double(windowSize)
    }

    mutating func recordTrainMetrics(_ metrics: [String: Double]) {
        if let loss = metrics["loss"] {
            lossHistory.append(loss)
        }
        if let td = metrics["tdError"] {
            tdErrorHistory.append(td)
        }
        if let q = metrics["meanQValue"] {
            qValueHistory.append(q)
        }
        if let lr = metrics["learningRate"] {
            learningRateHistory.append(lr)
        }
    }
}

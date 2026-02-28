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
    private enum CodingKeys: String, CodingKey {
        case status
        case currentTimestep
        case episodeCount
        case meanReward
        case meanEpisodeLength
        case explorationRate
        case rewardHistory
        case rewardStepHistory
        case episodeLengthHistory
        case episodeLengthStepHistory
        case explorationRateHistory
        case explorationRateStepHistory
        case lossHistory
        case lossStepHistory
        case actorLossHistory
        case actorLossStepHistory
        case criticLossHistory
        case criticLossStepHistory
        case entropyCoefHistory
        case entropyCoefStepHistory
        case tdErrorHistory
        case tdErrorStepHistory
        case qValueHistory
        case qValueStepHistory
        case learningRateHistory
        case learningRateStepHistory
        case renderVersion
    }

    var status: TrainingStatus = .idle
    var currentTimestep: Int = 0
    var episodeCount: Int = 0
    var meanReward: Double?
    var meanEpisodeLength: Double?
    var explorationRate: Double?
    var rewardHistory: [Double] = []
    var rewardStepHistory: [Int] = []
    var episodeLengthHistory: [Double] = []
    var episodeLengthStepHistory: [Int] = []
    var explorationRateHistory: [Double] = []
    var explorationRateStepHistory: [Int] = []
    var lossHistory: [Double] = []
    var lossStepHistory: [Int] = []
    var actorLossHistory: [Double] = []
    var actorLossStepHistory: [Int] = []
    var criticLossHistory: [Double] = []
    var criticLossStepHistory: [Int] = []
    var entropyCoefHistory: [Double] = []
    var entropyCoefStepHistory: [Int] = []
    var tdErrorHistory: [Double] = []
    var tdErrorStepHistory: [Int] = []
    var qValueHistory: [Double] = []
    var qValueStepHistory: [Int] = []
    var learningRateHistory: [Double] = []
    var learningRateStepHistory: [Int] = []
    var renderVersion: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decodeIfPresent(TrainingStatus.self, forKey: .status) ?? .idle
        currentTimestep = try c.decodeIfPresent(Int.self, forKey: .currentTimestep) ?? 0
        episodeCount = try c.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
        meanReward = Self.finiteOrNil(
            try c.decodeIfPresent(Double.self, forKey: .meanReward)
        )
        meanEpisodeLength = Self.finiteOrNil(
            try c.decodeIfPresent(Double.self, forKey: .meanEpisodeLength)
        )
        explorationRate = Self.finiteOrNil(
            try c.decodeIfPresent(Double.self, forKey: .explorationRate)
        )
        let rewardSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .rewardStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .rewardHistory) ?? [],
            fallbackStart: 1
        )
        rewardStepHistory = rewardSeries.steps
        rewardHistory = rewardSeries.values

        let episodeLengthSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .episodeLengthStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .episodeLengthHistory) ?? [],
            fallbackStart: 1
        )
        episodeLengthStepHistory = episodeLengthSeries.steps
        episodeLengthHistory = episodeLengthSeries.values

        let explorationSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .explorationRateStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .explorationRateHistory) ?? [],
            fallbackStart: 1
        )
        explorationRateStepHistory = explorationSeries.steps
        explorationRateHistory = explorationSeries.values

        let lossSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .lossStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .lossHistory) ?? [],
            fallbackStart: 0
        )
        lossStepHistory = lossSeries.steps
        lossHistory = lossSeries.values

        let actorLossSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .actorLossStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .actorLossHistory) ?? [],
            fallbackStart: 0
        )
        actorLossStepHistory = actorLossSeries.steps
        actorLossHistory = actorLossSeries.values

        let criticLossSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .criticLossStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .criticLossHistory) ?? [],
            fallbackStart: 0
        )
        criticLossStepHistory = criticLossSeries.steps
        criticLossHistory = criticLossSeries.values

        let entropySeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .entropyCoefStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .entropyCoefHistory) ?? [],
            fallbackStart: 0
        )
        entropyCoefStepHistory = entropySeries.steps
        entropyCoefHistory = entropySeries.values

        let tdErrorSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .tdErrorStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .tdErrorHistory) ?? [],
            fallbackStart: 0
        )
        tdErrorStepHistory = tdErrorSeries.steps
        tdErrorHistory = tdErrorSeries.values

        let qValueSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .qValueStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .qValueHistory) ?? [],
            fallbackStart: 0
        )
        qValueStepHistory = qValueSeries.steps
        qValueHistory = qValueSeries.values

        let learningRateSeries = Self.sanitizeSeries(
            steps: try c.decodeIfPresent([Int].self, forKey: .learningRateStepHistory),
            values: try c.decodeIfPresent([Double].self, forKey: .learningRateHistory) ?? [],
            fallbackStart: 0
        )
        learningRateStepHistory = learningRateSeries.steps
        learningRateHistory = learningRateSeries.values
        renderVersion = try c.decodeIfPresent(Int.self, forKey: .renderVersion) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(status, forKey: .status)
        try c.encode(currentTimestep, forKey: .currentTimestep)
        try c.encode(episodeCount, forKey: .episodeCount)
        try c.encode(Self.finiteOrNil(meanReward), forKey: .meanReward)
        try c.encode(
            Self.finiteOrNil(meanEpisodeLength),
            forKey: .meanEpisodeLength
        )
        try c.encode(Self.finiteOrNil(explorationRate), forKey: .explorationRate)
        let rewardSeries = Self.sanitizeSeries(
            steps: rewardStepHistory,
            values: rewardHistory,
            fallbackStart: 1
        )
        try c.encode(rewardSeries.values, forKey: .rewardHistory)
        try c.encode(rewardSeries.steps, forKey: .rewardStepHistory)

        let episodeLengthSeries = Self.sanitizeSeries(
            steps: episodeLengthStepHistory,
            values: episodeLengthHistory,
            fallbackStart: 1
        )
        try c.encode(episodeLengthSeries.values, forKey: .episodeLengthHistory)
        try c.encode(episodeLengthSeries.steps, forKey: .episodeLengthStepHistory)

        let explorationSeries = Self.sanitizeSeries(
            steps: explorationRateStepHistory,
            values: explorationRateHistory,
            fallbackStart: 1
        )
        try c.encode(explorationSeries.values, forKey: .explorationRateHistory)
        try c.encode(explorationSeries.steps, forKey: .explorationRateStepHistory)

        let lossSeries = Self.sanitizeSeries(
            steps: lossStepHistory,
            values: lossHistory,
            fallbackStart: 0
        )
        try c.encode(lossSeries.values, forKey: .lossHistory)
        try c.encode(lossSeries.steps, forKey: .lossStepHistory)

        let actorLossSeries = Self.sanitizeSeries(
            steps: actorLossStepHistory,
            values: actorLossHistory,
            fallbackStart: 0
        )
        try c.encode(actorLossSeries.values, forKey: .actorLossHistory)
        try c.encode(actorLossSeries.steps, forKey: .actorLossStepHistory)

        let criticLossSeries = Self.sanitizeSeries(
            steps: criticLossStepHistory,
            values: criticLossHistory,
            fallbackStart: 0
        )
        try c.encode(criticLossSeries.values, forKey: .criticLossHistory)
        try c.encode(criticLossSeries.steps, forKey: .criticLossStepHistory)

        let entropySeries = Self.sanitizeSeries(
            steps: entropyCoefStepHistory,
            values: entropyCoefHistory,
            fallbackStart: 0
        )
        try c.encode(entropySeries.values, forKey: .entropyCoefHistory)
        try c.encode(entropySeries.steps, forKey: .entropyCoefStepHistory)

        let tdErrorSeries = Self.sanitizeSeries(
            steps: tdErrorStepHistory,
            values: tdErrorHistory,
            fallbackStart: 0
        )
        try c.encode(tdErrorSeries.values, forKey: .tdErrorHistory)
        try c.encode(tdErrorSeries.steps, forKey: .tdErrorStepHistory)

        let qValueSeries = Self.sanitizeSeries(
            steps: qValueStepHistory,
            values: qValueHistory,
            fallbackStart: 0
        )
        try c.encode(qValueSeries.values, forKey: .qValueHistory)
        try c.encode(qValueSeries.steps, forKey: .qValueStepHistory)

        let learningRateSeries = Self.sanitizeSeries(
            steps: learningRateStepHistory,
            values: learningRateHistory,
            fallbackStart: 0
        )
        try c.encode(learningRateSeries.values, forKey: .learningRateHistory)
        try c.encode(learningRateSeries.steps, forKey: .learningRateStepHistory)
        try c.encode(renderVersion, forKey: .renderVersion)
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
        rewardStepHistory = []
        episodeLengthHistory = []
        episodeLengthStepHistory = []
        explorationRateHistory = []
        explorationRateStepHistory = []
        lossHistory = []
        lossStepHistory = []
        actorLossHistory = []
        actorLossStepHistory = []
        criticLossHistory = []
        criticLossStepHistory = []
        entropyCoefHistory = []
        entropyCoefStepHistory = []
        tdErrorHistory = []
        tdErrorStepHistory = []
        qValueHistory = []
        qValueStepHistory = []
        learningRateHistory = []
        learningRateStepHistory = []
        renderVersion = 0
    }

    mutating func recordEpisode(reward: Double, length: Int, timestep: Int) {
        episodeCount += 1
        let safeStep = max(0, timestep)
        if reward.isFinite {
            Self.appendCapped(
                steps: &rewardStepHistory,
                values: &rewardHistory,
                step: safeStep,
                value: reward
            )
        }
        Self.appendCapped(
            steps: &episodeLengthStepHistory,
            values: &episodeLengthHistory,
            step: safeStep,
            value: Double(length)
        )

        if let rate = explorationRate, rate.isFinite {
            Self.appendCapped(
                steps: &explorationRateStepHistory,
                values: &explorationRateHistory,
                step: safeStep,
                value: rate
            )
        }

        let rewardWindow = min(100, rewardHistory.count)
        if rewardWindow > 0 {
            let recentRewards = rewardHistory.suffix(rewardWindow)
            meanReward = recentRewards.reduce(0, +) / Double(rewardWindow)
        } else {
            meanReward = nil
        }

        let lengthWindow = min(100, episodeLengthHistory.count)
        if lengthWindow > 0 {
            let recentLengths = episodeLengthHistory.suffix(lengthWindow)
            meanEpisodeLength = recentLengths.reduce(0, +) / Double(lengthWindow)
        } else {
            meanEpisodeLength = nil
        }
    }

    mutating func recordTrainMetrics(_ metrics: [String: Double], timestep: Int) {
        let safeStep = max(0, timestep)
        let lossValue = Self.metricValue(
            in: metrics,
            keys: ["loss", "train/loss"]
        )
        let criticLossValue = Self.metricValue(
            in: metrics,
            keys: ["criticLoss", "train/critic_loss", "train/value_loss"]
        )
        if let loss = lossValue, loss.isFinite {
            let sameAsCritic: Bool = {
                guard let criticLossValue, criticLossValue.isFinite else { return false }
                let scale = max(1.0, max(abs(loss), abs(criticLossValue)))
                return abs(loss - criticLossValue) <= (1e-6 * scale)
            }()
            if !sameAsCritic {
                Self.appendCapped(
                    steps: &lossStepHistory,
                    values: &lossHistory,
                    step: safeStep,
                    value: loss
                )
            }
        }
        if let criticLoss = criticLossValue, criticLoss.isFinite {
            Self.appendCapped(
                steps: &criticLossStepHistory,
                values: &criticLossHistory,
                step: safeStep,
                value: criticLoss
            )
        }
        if let actorLoss = Self.metricValue(
            in: metrics,
            keys: ["actorLoss", "train/actor_loss", "train/policy_loss"]
        ), actorLoss.isFinite {
            Self.appendCapped(
                steps: &actorLossStepHistory,
                values: &actorLossHistory,
                step: safeStep,
                value: actorLoss
            )
        }
        if let entCoef = Self.metricValue(
            in: metrics,
            keys: ["entCoef", "train/ent_coef"]
        ), entCoef.isFinite {
            Self.appendCapped(
                steps: &entropyCoefStepHistory,
                values: &entropyCoefHistory,
                step: safeStep,
                value: entCoef
            )
        }
        if let td = metrics["tdError"], td.isFinite {
            Self.appendCapped(
                steps: &tdErrorStepHistory,
                values: &tdErrorHistory,
                step: safeStep,
                value: td
            )
        }
        if let q = Self.metricValue(
            in: metrics,
            keys: ["meanQValue"]
        ), q.isFinite {
            Self.appendCapped(
                steps: &qValueStepHistory,
                values: &qValueHistory,
                step: safeStep,
                value: q
            )
        }
        if let lr = Self.metricValue(
            in: metrics,
            keys: ["learningRate", "train/learning_rate"]
        ), lr.isFinite {
            Self.appendCapped(
                steps: &learningRateStepHistory,
                values: &learningRateHistory,
                step: safeStep,
                value: lr
            )
        }
    }

    private static let maxHistoryCount = 20_000
    private static let trimBatch = 2_000

    private static func appendCapped(
        steps: inout [Int],
        values: inout [Double],
        step: Int,
        value: Double
    ) {
        steps.append(max(0, step))
        values.append(value)
        if values.count > Self.maxHistoryCount + Self.trimBatch {
            let removeCount = values.count - Self.maxHistoryCount
            values.removeFirst(removeCount)
            steps.removeFirst(removeCount)
        }
    }

    private static func sanitizeSeries(
        steps: [Int]?,
        values: [Double],
        fallbackStart: Int
    ) -> (steps: [Int], values: [Double]) {
        if values.isEmpty {
            return ([], [])
        }
        let fallback = Array(fallbackStart..<(fallbackStart + values.count))
        let stepSource = steps ?? fallback
        let count = min(values.count, stepSource.count)
        if count == 0 {
            return ([], [])
        }
        var sanitizedSteps: [Int] = []
        var sanitizedValues: [Double] = []
        sanitizedSteps.reserveCapacity(count)
        sanitizedValues.reserveCapacity(count)
        for i in 0..<count {
            let value = values[i]
            if value.isFinite {
                sanitizedSteps.append(max(0, stepSource[i]))
                sanitizedValues.append(value)
            }
        }
        return (sanitizedSteps, sanitizedValues)
    }

    private static func finiteOrNil(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return value
    }

    private static func metricValue(in metrics: [String: Double], keys: [String]) -> Double? {
        for key in keys {
            if let value = metrics[key] {
                return value
            }
        }
        return nil
    }
}

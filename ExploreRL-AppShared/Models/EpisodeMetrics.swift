//
//  EpisodeMetrics.swift
//

import Foundation

struct EpisodeMetrics: Identifiable, Sendable {
    let id = UUID()
    let episode: Int
    let reward: Double
    let steps: Int
    let success: Bool
    let averageTDError: Double
    let averageLoss: Double?
    let averageMaxQ: Double
    let epsilon: Double
    let alpha: Double?
    let averageGradNorm: Double?
    let rewardMovingAverage: Double?
    let meanLogProb: Double?
    let entropyEstimate: Double?

    init(
        episode: Int,
        reward: Double,
        steps: Int,
        success: Bool,
        averageTDError: Double,
        averageLoss: Double?,
        averageMaxQ: Double,
        epsilon: Double,
        alpha: Double?,
        averageGradNorm: Double?,
        rewardMovingAverage: Double?,
        meanLogProb: Double? = nil,
        entropyEstimate: Double? = nil
    ) {
        self.episode = episode
        self.reward = reward
        self.steps = steps
        self.success = success
        self.averageTDError = averageTDError
        self.averageLoss = averageLoss
        self.averageMaxQ = averageMaxQ
        self.epsilon = epsilon
        self.alpha = alpha
        self.averageGradNorm = averageGradNorm
        self.rewardMovingAverage = rewardMovingAverage
        self.meanLogProb = meanLogProb
        self.entropyEstimate = entropyEstimate
    }
}


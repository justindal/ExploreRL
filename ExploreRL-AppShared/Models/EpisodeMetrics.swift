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
    let averageGradNorm: Double?
    let rewardMovingAverage: Double?
}


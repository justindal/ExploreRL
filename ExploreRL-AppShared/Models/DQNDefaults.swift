//
//  DQNDefaults.swift
//

import Foundation

struct DQNDefaults {
    // Core DQN
    static let learningRate: Double = 0.0001
    static let gamma: Double = 0.99
    static let epsilon: Double = 0.9
    static let epsilonMin: Double = 0.01
    static let epsilonDecaySteps: Int = 2_500
    static let tau: Double = 0.005
    static let batchSize: Int = 64
    static let gradClipNorm: Double = 100.0
    
    // Training loop settings
    static let warmupSteps: Int = 0
    static let maxStepsPerEpisode: Int = 500
    static let episodesPerRun: Int = 1000
    static let renderEnabled: Bool = true
    static let targetFPS: Double = 60.0
    static let turboMode: Bool = false
    
    // Advanced
    static let useSeed: Bool = false
    static let seed: Int = 0
    static let earlyStopEnabled: Bool = false
    static let earlyStopWindow: Int = 100
    static let earlyStopRewardThreshold: Double = 195.0
    static let clipReward: Bool = false
    static let clipRewardMin: Double = -1.0
    static let clipRewardMax: Double = 1.0
}

//
//  TrainingDefaults.swift
//  ExploreRL
//
//  Shared defaults for training loop and UI settings across all environments
//

import Foundation

struct TrainingDefaults {
    // Training loop settings
    static let episodesPerRun: Int = 1000
    static let maxStepsPerEpisode: Int = 500
    static let warmupSteps: Int = 0
    
    // Rendering settings
    static let renderEnabled: Bool = true
    static let targetFPS: Double = 60.0
    static let turboMode: Bool = false
    
    // Seed settings
    static let useSeed: Bool = false
    static let seed: Int = 0
    
    // Early stopping
    static let earlyStopEnabled: Bool = false
    static let earlyStopWindow: Int = 100
    
    // Reward clipping
    static let clipReward: Bool = false
    static let clipRewardMin: Double = -1.0
    static let clipRewardMax: Double = 1.0
}


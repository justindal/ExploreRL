//
//  SavedAgent.swift
//

import Foundation
import SwiftUI

/// Represents a saved RL agent that can be loaded for evaluation or continued training
struct SavedAgent: Identifiable, Codable {
    let id: UUID
    var name: String
    let environmentType: EnvironmentType
    let algorithmType: String
    let createdAt: Date
    var updatedAt: Date
    
    let episodesTrained: Int
    let finalEpsilon: Double
    let bestReward: Double
    let averageReward: Double
    let successRate: Double?
    
    let hyperparameters: [String: Double]
    
    let environmentConfig: [String: String]
    
    let agentDataPath: String
}

struct SavedAgentSummary: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    let environmentType: EnvironmentType
    let algorithmType: String
    let createdAt: Date
    var updatedAt: Date
    let episodesTrained: Int
    let bestReward: Double
    let averageReward: Double
    let successRate: Double?
    var fileSize: Int64 = 0
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

extension SavedAgent {
    func summary(fileSize: Int64 = 0) -> SavedAgentSummary {
        SavedAgentSummary(
            id: id,
            name: name,
            environmentType: environmentType,
            algorithmType: algorithmType,
            createdAt: createdAt,
            updatedAt: updatedAt,
            episodesTrained: episodesTrained,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: successRate,
            fileSize: fileSize
        )
    }
}

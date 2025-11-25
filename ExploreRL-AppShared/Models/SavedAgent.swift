//
//  SavedAgent.swift
//

import Foundation

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
    
    enum EnvironmentType: String, Codable, CaseIterable {
        case frozenLake = "FrozenLake"
        case cartPole = "CartPole"
        
        var displayName: String {
            switch self {
            case .frozenLake: return "Frozen Lake"
            case .cartPole: return "Cart Pole"
            }
        }
        
        var iconName: String {
            switch self {
            case .frozenLake: return "snowflake"
            case .cartPole: return "cart"
            }
        }
    }
}

/// Lightweight version for listing without loading full agent data
struct SavedAgentSummary: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    let environmentType: SavedAgent.EnvironmentType
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


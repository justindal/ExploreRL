//
//  SavedAgent.swift
//

import Foundation
import SwiftUI

/// Describes a single layer in a neural network
struct LayerInfo: Codable, Hashable {
    let name: String
    let inputSize: Int
    let outputSize: Int
    let activation: String
    let hasBias: Bool
    
    init(name: String, inputSize: Int, outputSize: Int, activation: String = "relu", hasBias: Bool = true) {
        self.name = name
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.activation = activation
        self.hasBias = hasBias
    }
}

/// Describes the full network architecture for CoreML conversion
struct NetworkArchitecture: Codable, Hashable {
    let networkType: String
    let inputSize: Int
    let outputSize: Int
    let hiddenSizes: [Int]
    let activations: [String]
    let outputActivation: String?
    
    /// Convenience initializer for simple MLPs
    init(networkType: String, inputSize: Int, outputSize: Int, hiddenSizes: [Int], 
         hiddenActivation: String = "relu", outputActivation: String? = nil) {
        self.networkType = networkType
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.hiddenSizes = hiddenSizes
        self.outputActivation = outputActivation
        
        var acts = [String](repeating: hiddenActivation, count: hiddenSizes.count)
        acts.append(outputActivation ?? "none")
        self.activations = acts
    }
}

/// Represents a saved RL agent that can be loaded for evaluation or continued training
struct SavedAgent: Identifiable, Codable {
    let id: UUID
    var name: String
    let environmentType: EnvironmentType
    let algorithmType: String
    let createdAt: Date
    var updatedAt: Date
    
    let episodesTrained: Int
    let trainingTimeSeconds: Double?
    let finalEpsilon: Double
    let bestReward: Double
    let averageReward: Double
    let successRate: Double?
    
    let hyperparameters: [String: Double]
    
    let environmentConfig: [String: String]
    
    let agentDataPath: String
    
    /// Network architecture info for CoreML conversion
    let networkArchitecture: [NetworkArchitecture]?
    
    init(id: UUID, name: String, environmentType: EnvironmentType, algorithmType: String,
         createdAt: Date, updatedAt: Date, episodesTrained: Int, trainingTimeSeconds: Double? = nil, finalEpsilon: Double,
         bestReward: Double, averageReward: Double, successRate: Double?,
         hyperparameters: [String: Double], environmentConfig: [String: String],
         agentDataPath: String, networkArchitecture: [NetworkArchitecture]? = nil) {
        self.id = id
        self.name = name
        self.environmentType = environmentType
        self.algorithmType = algorithmType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.episodesTrained = episodesTrained
        self.trainingTimeSeconds = trainingTimeSeconds
        self.finalEpsilon = finalEpsilon
        self.bestReward = bestReward
        self.averageReward = averageReward
        self.successRate = successRate
        self.hyperparameters = hyperparameters
        self.environmentConfig = environmentConfig
        self.agentDataPath = agentDataPath
        self.networkArchitecture = networkArchitecture
    }
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

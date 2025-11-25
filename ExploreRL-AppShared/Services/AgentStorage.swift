//
//  AgentStorage.swift
//

import Foundation
import SwiftUI
import MLX
import MLXNN
import ExploreRLCore

/// Storage manager for trained agents
@MainActor
@Observable class AgentStorage {
    static let shared = AgentStorage()
    
    private(set) var savedAgents: [SavedAgentSummary] = []
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var agentsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let agentsDir = appSupport.appendingPathComponent("ExploreRL/SavedAgents", isDirectory: true)
        
        if !fileManager.fileExists(atPath: agentsDir.path) {
            try? fileManager.createDirectory(at: agentsDir, withIntermediateDirectories: true)
        }
        
        return agentsDir
    }
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadAgentList()
    }
    
    func loadAgentList() {
        do {
            let files = try fileManager.contentsOfDirectory(at: agentsDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let metadataFiles = files.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("_metadata") }
            
            var agents: [SavedAgentSummary] = []
            for file in metadataFiles {
                if let data = try? Data(contentsOf: file),
                   let agent = try? decoder.decode(SavedAgent.self, from: data) {
                    // Calculate total file size (metadata + data file)
                    let fileSize = calculateFileSize(for: agent)
                    agents.append(agent.summary(fileSize: fileSize))
                }
            }
            
            savedAgents = agents.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            print("Failed to load agent list: \(error)")
            savedAgents = []
        }
    }
    
    private func calculateFileSize(for agent: SavedAgent) -> Int64 {
        var totalSize: Int64 = 0
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(agent.id.uuidString)_metadata.json")
        if let attrs = try? fileManager.attributesOfItem(atPath: metadataPath.path),
           let size = attrs[.size] as? Int64 {
            totalSize += size
        }
        
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        if let attrs = try? fileManager.attributesOfItem(atPath: dataPath.path),
           let size = attrs[.size] as? Int64 {
            totalSize += size
        }
        
        return totalSize
    }
    
    func getFileSize(for agentId: UUID) -> Int64 {
        guard let agent = try? loadAgent(id: agentId) else { return 0 }
        return calculateFileSize(for: agent)
    }
    
    func saveFrozenLakeAgent(
        name: String,
        qTable: MLXArray,
        algorithm: String,
        episodesTrained: Int,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        successRate: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String]
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let dataFileName = "\(id.uuidString)_qtable.npy"
        let dataPath = agentsDirectory.appendingPathComponent(dataFileName)
        
        try MLX.save(array: qTable, url: dataPath)
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: .frozenLake,
            algorithmType: algorithm,
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: successRate,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            agentDataPath: dataFileName
        )
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        let data = try encoder.encode(agent)
        try data.write(to: metadataPath)
        
        loadAgentList()
        return agent
    }
    
    func saveCartPoleAgent(
        name: String,
        policyNetwork: QNetwork,
        episodesTrained: Int,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String]
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let dataFileName = "\(id.uuidString)_weights.safetensors"
        let dataPath = agentsDirectory.appendingPathComponent(dataFileName)
        
        let weights = policyNetwork.parameters()
        let flatWeights = weights.flattened()
        var weightsDict: [String: MLXArray] = [:]
        for (key, value) in flatWeights {
            weightsDict[key] = value
        }
        try MLX.save(arrays: weightsDict, url: dataPath)
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: .cartPole,
            algorithmType: "DQN",
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            agentDataPath: dataFileName
        )
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        let data = try encoder.encode(agent)
        try data.write(to: metadataPath)
        
        loadAgentList()
        return agent
    }
    
    func loadAgent(id: UUID) throws -> SavedAgent {
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        let data = try Data(contentsOf: metadataPath)
        return try decoder.decode(SavedAgent.self, from: data)
    }
    
    func loadQTable(for agent: SavedAgent) throws -> MLXArray {
        guard agent.environmentType == .frozenLake else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        return try MLX.loadArray(url: dataPath)
    }
    
    func loadNetworkWeights(for agent: SavedAgent) throws -> [String: MLXArray] {
        guard agent.environmentType == .cartPole else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        return try MLX.loadArrays(url: dataPath)
    }
    
    func renameAgent(id: UUID, newName: String) throws {
        var agent = try loadAgent(id: id)
        agent.name = newName
        agent.updatedAt = Date()
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        let data = try encoder.encode(agent)
        try data.write(to: metadataPath)
        
        loadAgentList()
    }
    
    func updateFrozenLakeAgent(
        id: UUID,
        newName: String,
        qTable: MLXArray,
        episodesTrained: Int,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        successRate: Double,
        hyperparameters: [String: Double]
    ) throws {
        var agent = try loadAgent(id: id)
        
        agent.name = newName
        agent.updatedAt = Date()
        
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        try MLX.save(array: qTable, url: dataPath)
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: successRate,
            hyperparameters: hyperparameters,
            environmentConfig: agent.environmentConfig,
            agentDataPath: agent.agentDataPath
        )
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        let data = try encoder.encode(updatedAgent)
        try data.write(to: metadataPath)
        
        loadAgentList()
    }
    
    func updateCartPoleAgent(
        id: UUID,
        newName: String,
        policyNetwork: QNetwork,
        episodesTrained: Int,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        var agent = try loadAgent(id: id)
        
        agent.name = newName
        agent.updatedAt = Date()
        
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        let weights = policyNetwork.parameters()
        let flatWeights = weights.flattened()
        var weightsDict: [String: MLXArray] = [:]
        for (key, value) in flatWeights {
            weightsDict[key] = value
        }
        try MLX.save(arrays: weightsDict, url: dataPath)
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: agent.environmentConfig,
            agentDataPath: agent.agentDataPath
        )
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        let data = try encoder.encode(updatedAgent)
        try data.write(to: metadataPath)
        
        loadAgentList()
    }
    
    func deleteAgent(id: UUID) throws {
        let agent = try loadAgent(id: id)
        
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        try? fileManager.removeItem(at: dataPath)
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        try fileManager.removeItem(at: metadataPath)
        
        loadAgentList()
    }
    
    func agents(for environmentType: SavedAgent.EnvironmentType) -> [SavedAgentSummary] {
        savedAgents.filter { $0.environmentType == environmentType }
    }
}

enum AgentStorageError: LocalizedError {
    case wrongEnvironmentType
    case agentNotFound
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .wrongEnvironmentType:
            return "Agent is for a different environment type"
        case .agentNotFound:
            return "Agent not found"
        case .dataCorrupted:
            return "Agent data is corrupted"
        }
    }
}


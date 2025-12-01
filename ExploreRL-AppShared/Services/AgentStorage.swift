//
//  AgentStorage.swift
//

import Foundation
import SwiftUI
import MLX
import MLXNN
import Gymnazo

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
        let agent = try loadAgent(id: id)
        
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
    
    func loadQTable(for agent: SavedAgent) throws -> MLXArray {
        guard agent.environmentType == .frozenLake else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        return try MLX.loadArray(url: dataPath)
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
        let agent = try loadAgent(id: id)
        
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
    
    
    func saveMountainCarAgent(
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
            environmentType: .mountainCar,
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
    
    func updateMountainCarAgent(
        id: UUID,
        newName: String,
        policyNetwork: QNetwork,
        episodesTrained: Int,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        let agent = try loadAgent(id: id)
        
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
    
    
    func saveMountainCarContinuousAgent(
        name: String,
        actor: SACActorNetwork,
        qf1: SoftQNetwork,
        qf2: SoftQNetwork,
        episodesTrained: Int,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String]
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let dataFileName = "\(id.uuidString)_sac_weights.safetensors"
        let dataPath = agentsDirectory.appendingPathComponent(dataFileName)
        
        var combinedWeights: [String: MLXArray] = [:]
        
        let actorWeights = actor.parameters().flattened()
        for (key, value) in actorWeights {
            combinedWeights["actor.\(key)"] = value
        }
        
        let qf1Weights = qf1.parameters().flattened()
        for (key, value) in qf1Weights {
            combinedWeights["qf1.\(key)"] = value
        }
        
        let qf2Weights = qf2.parameters().flattened()
        for (key, value) in qf2Weights {
            combinedWeights["qf2.\(key)"] = value
        }
        
        try MLX.save(arrays: combinedWeights, url: dataPath)
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: .mountainCarContinuous,
            algorithmType: "SAC",
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            finalEpsilon: alpha,
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
    
    func updateMountainCarContinuousAgent(
        id: UUID,
        newName: String,
        actor: SACActorNetwork,
        qf1: SoftQNetwork,
        qf2: SoftQNetwork,
        episodesTrained: Int,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        let agent = try loadAgent(id: id)
        
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        
        var combinedWeights: [String: MLXArray] = [:]
        
        let actorWeights = actor.parameters().flattened()
        for (key, value) in actorWeights {
            combinedWeights["actor.\(key)"] = value
        }
        
        let qf1Weights = qf1.parameters().flattened()
        for (key, value) in qf1Weights {
            combinedWeights["qf1.\(key)"] = value
        }
        
        let qf2Weights = qf2.parameters().flattened()
        for (key, value) in qf2Weights {
            combinedWeights["qf2.\(key)"] = value
        }
        
        try MLX.save(arrays: combinedWeights, url: dataPath)
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            finalEpsilon: alpha,
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
    
    
    func loadAgent(id: UUID) throws -> SavedAgent {
        let metadataPath = agentsDirectory.appendingPathComponent("\(id.uuidString)_metadata.json")
        let data = try Data(contentsOf: metadataPath)
        return try decoder.decode(SavedAgent.self, from: data)
    }
    
    func loadNetworkWeights(for agent: SavedAgent) throws -> [String: MLXArray] {
        guard agent.environmentType == .cartPole || agent.environmentType == .mountainCar else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        return try MLX.loadArrays(url: dataPath)
    }
    
    func loadSACWeights(for agent: SavedAgent) throws -> [String: [String: MLXArray]] {
        guard agent.environmentType == .mountainCarContinuous else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        let allWeights = try MLX.loadArrays(url: dataPath)
        
        var actorWeights: [String: MLXArray] = [:]
        var qf1Weights: [String: MLXArray] = [:]
        var qf2Weights: [String: MLXArray] = [:]
        
        for (key, value) in allWeights {
            if key.hasPrefix("actor.") {
                let strippedKey = String(key.dropFirst("actor.".count))
                actorWeights[strippedKey] = value
            } else if key.hasPrefix("qf1.") {
                let strippedKey = String(key.dropFirst("qf1.".count))
                qf1Weights[strippedKey] = value
            } else if key.hasPrefix("qf2.") {
                let strippedKey = String(key.dropFirst("qf2.".count))
                qf2Weights[strippedKey] = value
            }
        }
        
        return [
            "actor": actorWeights,
            "qf1": qf1Weights,
            "qf2": qf2Weights
        ]
    }
    
    
    func saveMountainCarContinuousAgentVmap(
        name: String,
        actor: SACActorNetwork,
        qEnsemble: EnsembleQNetwork,
        episodesTrained: Int,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String]
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let dataFileName = "\(id.uuidString)_sac_vmap_weights.safetensors"
        let dataPath = agentsDirectory.appendingPathComponent(dataFileName)
        
        var combinedWeights: [String: MLXArray] = [:]
        
        let actorWeights = actor.parameters().flattened()
        for (key, value) in actorWeights {
            combinedWeights["actor.\(key)"] = value
        }
        
        let qEnsembleWeights = qEnsemble.parameters().flattened()
        for (key, value) in qEnsembleWeights {
            combinedWeights["qEnsemble.\(key)"] = value
        }
        
        try MLX.save(arrays: combinedWeights, url: dataPath)
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: .mountainCarContinuous,
            algorithmType: "SAC-Vmap",
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            finalEpsilon: alpha,
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
    
    func updateMountainCarContinuousAgentVmap(
        id: UUID,
        newName: String,
        actor: SACActorNetwork,
        qEnsemble: EnsembleQNetwork,
        episodesTrained: Int,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        let agent = try loadAgent(id: id)
        
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        
        var combinedWeights: [String: MLXArray] = [:]
        
        let actorWeights = actor.parameters().flattened()
        for (key, value) in actorWeights {
            combinedWeights["actor.\(key)"] = value
        }
        
        let qEnsembleWeights = qEnsemble.parameters().flattened()
        for (key, value) in qEnsembleWeights {
            combinedWeights["qEnsemble.\(key)"] = value
        }
        
        try MLX.save(arrays: combinedWeights, url: dataPath)
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            finalEpsilon: alpha,
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
    
    func loadSACVmapWeights(for agent: SavedAgent) throws -> [String: [String: MLXArray]] {
        guard agent.environmentType == .mountainCarContinuous else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        let allWeights = try MLX.loadArrays(url: dataPath)
        
        var actorWeights: [String: MLXArray] = [:]
        var qEnsembleWeights: [String: MLXArray] = [:]
        
        for (key, value) in allWeights {
            if key.hasPrefix("actor.") {
                let strippedKey = String(key.dropFirst("actor.".count))
                actorWeights[strippedKey] = value
            } else if key.hasPrefix("qEnsemble.") {
                let strippedKey = String(key.dropFirst("qEnsemble.".count))
                qEnsembleWeights[strippedKey] = value
            }
        }
        
        return [
            "actor": actorWeights,
            "qEnsemble": qEnsembleWeights
        ]
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
    
    func duplicateAgent(id: UUID) throws {
        let original = try loadAgent(id: id)
        let newId = UUID()
        let now = Date()
        
        let originalDataPath = agentsDirectory.appendingPathComponent(original.agentDataPath)
        let fileExtension = (original.agentDataPath as NSString).pathExtension
        let newDataFileName = "\(newId.uuidString)_\(fileExtension.isEmpty ? "data" : original.agentDataPath.components(separatedBy: "_").dropFirst().joined(separator: "_"))"
        let newDataPath = agentsDirectory.appendingPathComponent(newDataFileName)
        
        try fileManager.copyItem(at: originalDataPath, to: newDataPath)
        
        let newAgent = SavedAgent(
            id: newId,
            name: "\(original.name) Copy",
            environmentType: original.environmentType,
            algorithmType: original.algorithmType,
            createdAt: now,
            updatedAt: now,
            episodesTrained: original.episodesTrained,
            finalEpsilon: original.finalEpsilon,
            bestReward: original.bestReward,
            averageReward: original.averageReward,
            successRate: original.successRate,
            hyperparameters: original.hyperparameters,
            environmentConfig: original.environmentConfig,
            agentDataPath: newDataFileName
        )
        
        let metadataPath = agentsDirectory.appendingPathComponent("\(newId.uuidString)_metadata.json")
        let data = try encoder.encode(newAgent)
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
    
    func agents(for environmentType: EnvironmentType) -> [SavedAgentSummary] {
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

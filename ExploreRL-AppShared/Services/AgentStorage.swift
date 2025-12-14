//
//  AgentStorage.swift
//

import Foundation
import SwiftUI
import MLX
import MLXNN
import Gymnazo

/// Storage manager for trained agents
/// SavedAgents/{Environment}/{AgentName}/metadata.json + weights file
@MainActor
@Observable class AgentStorage {
    static let shared = AgentStorage()
    
    private(set) var savedAgents: [SavedAgentSummary] = []
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    
    private var agentsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let agentsDir = documents.appendingPathComponent("SavedAgents", isDirectory: true)
        
        if !fileManager.fileExists(atPath: agentsDir.path) {
            try? fileManager.createDirectory(at: agentsDir, withIntermediateDirectories: true)
        }
        
        return agentsDir
    }
    
    /// Get the directory for a specific environment type
    private func environmentDirectory(for type: EnvironmentType) -> URL {
        let envDir = agentsDirectory.appendingPathComponent(type.displayName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: envDir.path) {
            try? fileManager.createDirectory(at: envDir, withIntermediateDirectories: true)
        }
        
        return envDir
    }
    
    /// Create a unique agent folder with the given name
    private func createAgentFolder(name: String, environmentType: EnvironmentType) -> URL {
        let envDir = environmentDirectory(for: environmentType)
        let sanitizedName = sanitizeFolderName(name)
        var folderName = sanitizedName
        var counter = 1
        
        // Ensure unique folder name
        var agentDir = envDir.appendingPathComponent(folderName, isDirectory: true)
        while fileManager.fileExists(atPath: agentDir.path) {
            folderName = "\(sanitizedName) (\(counter))"
            counter += 1
            agentDir = envDir.appendingPathComponent(folderName, isDirectory: true)
        }
        
        try? fileManager.createDirectory(at: agentDir, withIntermediateDirectories: true)
        return agentDir
    }
    
    /// Sanitize a name for use as a folder name
    private func sanitizeFolderName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        var sanitized = name.components(separatedBy: invalidChars).joined(separator: "_")
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.isEmpty { sanitized = "Untitled" }
        return sanitized
    }
    
    /// Get the agent folder URL for an existing agent
    private func agentFolder(for agent: SavedAgent) -> URL {
        // Environment/AgentFolder/weights.safetensors
        let pathComponents = agent.agentDataPath.components(separatedBy: "/")
        if pathComponents.count >= 2 {
            let folderPath = pathComponents.dropLast().joined(separator: "/")
            return agentsDirectory.appendingPathComponent(folderPath, isDirectory: true)
        }
        return agentsDirectory
    }
    
    private var legacyAgentsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ExploreRL/SavedAgents", isDirectory: true)
    }
    
    /// Migrates agents from previous locations to new document folder structure
    private func migrateFromLegacyLocations() {
        migrateFromApplicationSupport()
        
        migrateToFolderStructure()
    }
    
    private func migrateFromApplicationSupport() {
        let legacyDir = legacyAgentsDirectory
        guard fileManager.fileExists(atPath: legacyDir.path) else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: legacyDir, includingPropertiesForKeys: nil)
            
            for file in files {
                let destinationURL = agentsDirectory.appendingPathComponent(file.lastPathComponent)
                guard !fileManager.fileExists(atPath: destinationURL.path) else { continue }
                try fileManager.moveItem(at: file, to: destinationURL)
            }
            
            let remainingFiles = try? fileManager.contentsOfDirectory(at: legacyDir, includingPropertiesForKeys: nil)
            if remainingFiles?.isEmpty == true {
                try? fileManager.removeItem(at: legacyDir)
            }
        } catch {
            print("Migration from Application Support error: \(error)")
        }
    }
    
    /// Migrate agents to folder structure from previous version
    private func migrateToFolderStructure() {
        do {
            let files = try fileManager.contentsOfDirectory(at: agentsDirectory, includingPropertiesForKeys: nil)
            let metadataFiles = files.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("_metadata") }
            
            for metadataFile in metadataFiles {
                guard let data = try? Data(contentsOf: metadataFile),
                      let agent = try? decoder.decode(SavedAgent.self, from: data) else { continue }
                
                if agent.agentDataPath.contains("/") { continue }
                
                let agentDir = createAgentFolder(name: agent.name, environmentType: agent.environmentType)
                let envName = agent.environmentType.displayName
                let folderName = agentDir.lastPathComponent
                
                let weightsFileName = getWeightsFileName(for: agent.environmentType, algorithm: agent.algorithmType)
                let newDataPath = "\(envName)/\(folderName)/\(weightsFileName)"
                
                let oldWeightsPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
                let newWeightsPath = agentDir.appendingPathComponent(weightsFileName)
                if fileManager.fileExists(atPath: oldWeightsPath.path) {
                    try? fileManager.moveItem(at: oldWeightsPath, to: newWeightsPath)
                }
                
                let updatedAgent = SavedAgent(
                    id: agent.id,
                    name: agent.name,
                    environmentType: agent.environmentType,
                    algorithmType: agent.algorithmType,
                    createdAt: agent.createdAt,
                    updatedAt: agent.updatedAt,
                    episodesTrained: agent.episodesTrained,
                    trainingTimeSeconds: agent.trainingTimeSeconds,
                    finalEpsilon: agent.finalEpsilon,
                    bestReward: agent.bestReward,
                    averageReward: agent.averageReward,
                    successRate: agent.successRate,
                    hyperparameters: agent.hyperparameters,
                    environmentConfig: agent.environmentConfig,
                    agentDataPath: newDataPath
                )
                
                let newMetadataPath = agentDir.appendingPathComponent("metadata.json")
                let encodedData = try encoder.encode(updatedAgent)
                try encodedData.write(to: newMetadataPath)
                
                try? fileManager.removeItem(at: metadataFile)
            }
        } catch {
            print("Migration to folder structure error: \(error)")
        }
    }
    
    private func getWeightsFileName(for envType: EnvironmentType, algorithm: String) -> String {
        switch envType {
        case .frozenLake:
            return "qtable.npy"
        case .cartPole, .mountainCar, .acrobot, .lunarLander:
            return "weights.safetensors"
        case .mountainCarContinuous:
            return algorithm == "SAC-Vmap" ? "sac_vmap_weights.safetensors" : "sac_weights.safetensors"
        case .pendulum, .lunarLanderContinuous:
            return "sac_weights.safetensors"
        }
    }
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601
        
        migrateFromLegacyLocations()
        loadAgentList()
    }
    
    func loadAgentList() {
        var agents: [SavedAgentSummary] = []
        
        for envType in EnvironmentType.allCases {
            let envDir = agentsDirectory.appendingPathComponent(envType.displayName, isDirectory: true)
            guard fileManager.fileExists(atPath: envDir.path) else { continue }
            
            do {
                let agentFolders = try fileManager.contentsOfDirectory(at: envDir, includingPropertiesForKeys: nil)
                    .filter { $0.hasDirectoryPath }
                
                for agentFolder in agentFolders {
                    let metadataPath = agentFolder.appendingPathComponent("metadata.json")
                    guard fileManager.fileExists(atPath: metadataPath.path),
                          let data = try? Data(contentsOf: metadataPath),
                          let agent = try? decoder.decode(SavedAgent.self, from: data) else { continue }
                    
                    let fileSize = calculateFolderSize(at: agentFolder)
                    agents.append(agent.summary(fileSize: fileSize))
                }
            } catch {
                print("Error scanning \(envType.displayName): \(error)")
            }
        }
        
        savedAgents = agents.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private func calculateFolderSize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = attrs.fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
    
    func getFileSize(for agentId: UUID) -> Int64 {
        guard let agent = try? loadAgent(id: agentId) else { return 0 }
        let folder = agentFolder(for: agent)
        return calculateFolderSize(at: folder)
    }
    
    private func saveWeights(_ weightsDict: [String: MLXArray], to url: URL) throws {
        try MLX.save(arrays: weightsDict, url: url)
    }
    
    private func saveQTable(_ qTable: MLXArray, to url: URL) throws {
        try MLX.save(array: qTable, url: url)
    }
    
    private func flattenNetworkWeights(_ network: Module) -> [String: MLXArray] {
        var weightsDict: [String: MLXArray] = [:]
        for (key, value) in network.parameters().flattened() {
            weightsDict[key] = value
        }
        return weightsDict
    }
    
    func saveFrozenLakeAgent(
        name: String,
        qTable: MLXArray,
        algorithm: String,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        successRate: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String]
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let agentDir = createAgentFolder(name: name, environmentType: .frozenLake)
        let folderName = agentDir.lastPathComponent
        let envName = EnvironmentType.frozenLake.displayName
        
        let weightsFileName = "qtable.npy"
        let dataPath = "\(envName)/\(folderName)/\(weightsFileName)"
        
        try saveQTable(qTable, to: agentDir.appendingPathComponent(weightsFileName))
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: .frozenLake,
            algorithmType: algorithm,
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: successRate,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            agentDataPath: dataPath
        )
        
        let metadataPath = agentDir.appendingPathComponent("metadata.json")
        try encoder.encode(agent).write(to: metadataPath)
        
        loadAgentList()
        return agent
    }
    
    func updateFrozenLakeAgent(
        id: UUID,
        newName: String,
        qTable: MLXArray,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        successRate: Double,
        hyperparameters: [String: Double]
    ) throws {
        let agent = try loadAgent(id: id)
        let folder = agentFolder(for: agent)
        
        let weightsPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        try saveQTable(qTable, to: weightsPath)
        
        var newDataPath = agent.agentDataPath
        var newFolder = folder
        if newName != agent.name {
            newFolder = try renameAgentFolder(from: folder, to: newName, environmentType: agent.environmentType)
            let envName = agent.environmentType.displayName
            newDataPath = "\(envName)/\(newFolder.lastPathComponent)/qtable.npy"
        }
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds ?? agent.trainingTimeSeconds,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: successRate,
            hyperparameters: hyperparameters,
            environmentConfig: agent.environmentConfig,
            agentDataPath: newDataPath
        )
        
        let metadataPath = newFolder.appendingPathComponent("metadata.json")
        try encoder.encode(updatedAgent).write(to: metadataPath)
        
        loadAgentList()
    }
    
    func loadQTable(for agent: SavedAgent) throws -> MLXArray {
        guard agent.environmentType == .frozenLake else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        return try MLX.loadArray(url: dataPath)
    }
    
    private func saveDQNAgent(
        name: String,
        policyNetwork: Module,
        environmentType: EnvironmentType,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        networkArchitecture: NetworkArchitecture? = nil
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let agentDir = createAgentFolder(name: name, environmentType: environmentType)
        let folderName = agentDir.lastPathComponent
        let envName = environmentType.displayName
        
        let weightsFileName = "weights.safetensors"
        let dataPath = "\(envName)/\(folderName)/\(weightsFileName)"
        
        let weightsDict = flattenNetworkWeights(policyNetwork)
        try saveWeights(weightsDict, to: agentDir.appendingPathComponent(weightsFileName))
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: environmentType,
            algorithmType: "DQN",
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            agentDataPath: dataPath,
            networkArchitecture: networkArchitecture != nil ? [networkArchitecture!] : nil
        )
        
        let metadataPath = agentDir.appendingPathComponent("metadata.json")
        try encoder.encode(agent).write(to: metadataPath)
        
        loadAgentList()
        return agent
    }
    
    private func updateDQNAgent(
        id: UUID,
        newName: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        let agent = try loadAgent(id: id)
        let folder = agentFolder(for: agent)
        
        let weightsPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        let weightsDict = flattenNetworkWeights(policyNetwork)
        try saveWeights(weightsDict, to: weightsPath)
        
        var newDataPath = agent.agentDataPath
        var newFolder = folder
        if newName != agent.name {
            newFolder = try renameAgentFolder(from: folder, to: newName, environmentType: agent.environmentType)
            let envName = agent.environmentType.displayName
            newDataPath = "\(envName)/\(newFolder.lastPathComponent)/weights.safetensors"
        }
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds ?? agent.trainingTimeSeconds,
            finalEpsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: agent.environmentConfig,
            agentDataPath: newDataPath
        )
        
        let metadataPath = newFolder.appendingPathComponent("metadata.json")
        try encoder.encode(updatedAgent).write(to: metadataPath)
        
        loadAgentList()
    }
    
    func saveCartPoleAgent(
        name: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 128
    ) throws -> SavedAgent {
        let architecture = NetworkArchitecture(
            networkType: "qNetwork",
            inputSize: 4,
            outputSize: 2,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        return try saveDQNAgent(
            name: name,
            policyNetwork: policyNetwork,
            environmentType: .cartPole,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            networkArchitecture: architecture
        )
    }
    
    func updateCartPoleAgent(
        id: UUID,
        newName: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        try updateDQNAgent(
            id: id,
            newName: newName,
            policyNetwork: policyNetwork,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters
        )
    }
    
    func saveMountainCarAgent(
        name: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 128
    ) throws -> SavedAgent {
        let architecture = NetworkArchitecture(
            networkType: "qNetwork",
            inputSize: 2,
            outputSize: 3,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        return try saveDQNAgent(
            name: name,
            policyNetwork: policyNetwork,
            environmentType: .mountainCar,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            networkArchitecture: architecture
        )
    }
    
    func updateMountainCarAgent(
        id: UUID,
        newName: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        try updateDQNAgent(
            id: id,
            newName: newName,
            policyNetwork: policyNetwork,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters
        )
    }
    
    func saveAcrobotAgent(
        name: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 128
    ) throws -> SavedAgent {
        let architecture = NetworkArchitecture(
            networkType: "qNetwork",
            inputSize: 6,
            outputSize: 3,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        return try saveDQNAgent(
            name: name,
            policyNetwork: policyNetwork,
            environmentType: .acrobot,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            networkArchitecture: architecture
        )
    }
    
    func updateAcrobotAgent(
        id: UUID,
        newName: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        try updateDQNAgent(
            id: id,
            newName: newName,
            policyNetwork: policyNetwork,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters
        )
    }
    
    func saveLunarLanderAgent(
        name: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 256
    ) throws -> SavedAgent {
        let architecture = NetworkArchitecture(
            networkType: "qNetwork",
            inputSize: 8,
            outputSize: 4,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        return try saveDQNAgent(
            name: name,
            policyNetwork: policyNetwork,
            environmentType: .lunarLander,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            networkArchitecture: architecture
        )
    }
    
    func updateLunarLanderAgent(
        id: UUID,
        newName: String,
        policyNetwork: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        epsilon: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        try updateDQNAgent(
            id: id,
            newName: newName,
            policyNetwork: policyNetwork,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            epsilon: epsilon,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters
        )
    }
    
    func loadNetworkWeights(for agent: SavedAgent) throws -> [String: MLXArray] {
        guard [.cartPole, .mountainCar, .acrobot, .lunarLander].contains(agent.environmentType) else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        return try MLX.loadArrays(url: dataPath)
    }
    
    func loadLunarLanderWeights(for agent: SavedAgent) throws -> [String: MLXArray] {
        guard agent.environmentType == .lunarLander else {
            throw AgentStorageError.wrongEnvironmentType
        }
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        return try MLX.loadArrays(url: dataPath)
    }
    
    private func saveSACAgent(
        name: String,
        actor: Module,
        qEnsemble: Module,
        environmentType: EnvironmentType,
        algorithmType: String = "SAC",
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        networkArchitectures: [NetworkArchitecture]? = nil
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let agentDir = createAgentFolder(name: name, environmentType: environmentType)
        let folderName = agentDir.lastPathComponent
        let envName = environmentType.displayName
        
        let weightsFileName = "sac_weights.safetensors"
        let dataPath = "\(envName)/\(folderName)/\(weightsFileName)"
        
        var combinedWeights: [String: MLXArray] = [:]
        for (key, value) in actor.parameters().flattened() {
            combinedWeights["actor.\(key)"] = value
        }
        for (key, value) in qEnsemble.parameters().flattened() {
            combinedWeights["qEnsemble.\(key)"] = value
        }
        
        try saveWeights(combinedWeights, to: agentDir.appendingPathComponent(weightsFileName))
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: environmentType,
            algorithmType: algorithmType,
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            finalEpsilon: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            agentDataPath: dataPath,
            networkArchitecture: networkArchitectures
        )
        
        let metadataPath = agentDir.appendingPathComponent("metadata.json")
        try encoder.encode(agent).write(to: metadataPath)
        
        loadAgentList()
        return agent
    }
    
    private func updateSACAgent(
        id: UUID,
        newName: String,
        actor: Module,
        qEnsemble: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        let agent = try loadAgent(id: id)
        let folder = agentFolder(for: agent)
        
        var combinedWeights: [String: MLXArray] = [:]
        for (key, value) in actor.parameters().flattened() {
            combinedWeights["actor.\(key)"] = value
        }
        for (key, value) in qEnsemble.parameters().flattened() {
            combinedWeights["qEnsemble.\(key)"] = value
        }
        
        let weightsPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        try saveWeights(combinedWeights, to: weightsPath)
        
        var newDataPath = agent.agentDataPath
        var newFolder = folder
        if newName != agent.name {
            newFolder = try renameAgentFolder(from: folder, to: newName, environmentType: agent.environmentType)
            let envName = agent.environmentType.displayName
            newDataPath = "\(envName)/\(newFolder.lastPathComponent)/sac_weights.safetensors"
        }
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds ?? agent.trainingTimeSeconds,
            finalEpsilon: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: agent.environmentConfig,
            agentDataPath: newDataPath
        )
        
        let metadataPath = newFolder.appendingPathComponent("metadata.json")
        try encoder.encode(updatedAgent).write(to: metadataPath)
        
        loadAgentList()
    }
    
    private func loadSACWeightsGeneric(for agent: SavedAgent) throws -> [String: [String: MLXArray]] {
        let dataPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        let allWeights = try MLX.loadArrays(url: dataPath)
        
        var actorWeights: [String: MLXArray] = [:]
        var qEnsembleWeights: [String: MLXArray] = [:]
        
        for (key, value) in allWeights {
            if key.hasPrefix("actor.") {
                actorWeights[String(key.dropFirst("actor.".count))] = value
            } else if key.hasPrefix("qEnsemble.") {
                qEnsembleWeights[String(key.dropFirst("qEnsemble.".count))] = value
            } else if key.hasPrefix("qf1.") {
                // Legacy twin Q-network format
                qEnsembleWeights[key] = value
            } else if key.hasPrefix("qf2.") {
                qEnsembleWeights[key] = value
            }
        }
        
        return ["actor": actorWeights, "qEnsemble": qEnsembleWeights]
    }
    
    func saveMountainCarContinuousAgent(
        name: String,
        actor: Module,
        qf1: Module,
        qf2: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 256
    ) throws -> SavedAgent {
        let id = UUID()
        let now = Date()
        let agentDir = createAgentFolder(name: name, environmentType: .mountainCarContinuous)
        let folderName = agentDir.lastPathComponent
        let envName = EnvironmentType.mountainCarContinuous.displayName
        
        let weightsFileName = "sac_weights.safetensors"
        let dataPath = "\(envName)/\(folderName)/\(weightsFileName)"
        
        var combinedWeights: [String: MLXArray] = [:]
        for (key, value) in actor.parameters().flattened() {
            combinedWeights["actor.\(key)"] = value
        }
        for (key, value) in qf1.parameters().flattened() {
            combinedWeights["qf1.\(key)"] = value
        }
        for (key, value) in qf2.parameters().flattened() {
            combinedWeights["qf2.\(key)"] = value
        }
        
        try saveWeights(combinedWeights, to: agentDir.appendingPathComponent(weightsFileName))
        
        let actorArch = NetworkArchitecture(
            networkType: "actor",
            inputSize: 2,
            outputSize: 2,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: "tanh"
        )
        let critic1Arch = NetworkArchitecture(
            networkType: "qf1",
            inputSize: 3,
            outputSize: 1,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        let critic2Arch = NetworkArchitecture(
            networkType: "qf2",
            inputSize: 3,
            outputSize: 1,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        let agent = SavedAgent(
            id: id,
            name: name,
            environmentType: .mountainCarContinuous,
            algorithmType: "SAC",
            createdAt: now,
            updatedAt: now,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            finalEpsilon: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            agentDataPath: dataPath,
            networkArchitecture: [actorArch, critic1Arch, critic2Arch]
        )
        
        let metadataPath = agentDir.appendingPathComponent("metadata.json")
        try encoder.encode(agent).write(to: metadataPath)
        
        loadAgentList()
        return agent
    }
    
    func updateMountainCarContinuousAgent(
        id: UUID,
        newName: String,
        actor: Module,
        qf1: Module,
        qf2: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        let agent = try loadAgent(id: id)
        let folder = agentFolder(for: agent)
        
        var combinedWeights: [String: MLXArray] = [:]
        for (key, value) in actor.parameters().flattened() {
            combinedWeights["actor.\(key)"] = value
        }
        for (key, value) in qf1.parameters().flattened() {
            combinedWeights["qf1.\(key)"] = value
        }
        for (key, value) in qf2.parameters().flattened() {
            combinedWeights["qf2.\(key)"] = value
        }
        
        let weightsPath = agentsDirectory.appendingPathComponent(agent.agentDataPath)
        try saveWeights(combinedWeights, to: weightsPath)
        
        var newDataPath = agent.agentDataPath
        var newFolder = folder
        if newName != agent.name {
            newFolder = try renameAgentFolder(from: folder, to: newName, environmentType: agent.environmentType)
            let envName = agent.environmentType.displayName
            newDataPath = "\(envName)/\(newFolder.lastPathComponent)/sac_weights.safetensors"
        }
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds ?? agent.trainingTimeSeconds,
            finalEpsilon: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            successRate: nil,
            hyperparameters: hyperparameters,
            environmentConfig: agent.environmentConfig,
            agentDataPath: newDataPath
        )
        
        let metadataPath = newFolder.appendingPathComponent("metadata.json")
        try encoder.encode(updatedAgent).write(to: metadataPath)
        
        loadAgentList()
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
                actorWeights[String(key.dropFirst("actor.".count))] = value
            } else if key.hasPrefix("qf1.") {
                qf1Weights[String(key.dropFirst("qf1.".count))] = value
            } else if key.hasPrefix("qf2.") {
                qf2Weights[String(key.dropFirst("qf2.".count))] = value
            }
        }
        
        return ["actor": actorWeights, "qf1": qf1Weights, "qf2": qf2Weights]
    }
    
    func saveMountainCarContinuousAgentVmap(
        name: String,
        actor: Module,
        qEnsemble: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 256
    ) throws -> SavedAgent {
        let actorArch = NetworkArchitecture(
            networkType: "actor",
            inputSize: 2,
            outputSize: 2,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: "tanh"
        )
        let criticArch = NetworkArchitecture(
            networkType: "qEnsemble",
            inputSize: 3,
            outputSize: 1,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        return try saveSACAgent(
            name: name,
            actor: actor,
            qEnsemble: qEnsemble,
            environmentType: .mountainCarContinuous,
            algorithmType: "SAC-Vmap",
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            alpha: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            networkArchitectures: [actorArch, criticArch]
        )
    }
    
    func updateMountainCarContinuousAgentVmap(
        id: UUID,
        newName: String,
        actor: Module,
        qEnsemble: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        try updateSACAgent(
            id: id,
            newName: newName,
            actor: actor,
            qEnsemble: qEnsemble,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            alpha: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters
        )
    }
    
    func loadSACVmapWeights(for agent: SavedAgent) throws -> [String: [String: MLXArray]] {
        guard agent.environmentType == .mountainCarContinuous else {
            throw AgentStorageError.wrongEnvironmentType
        }
        return try loadSACWeightsGeneric(for: agent)
    }
    
    func savePendulumAgent(
        name: String,
        actor: Module,
        qEnsemble: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 256
    ) throws -> SavedAgent {
        let actorArch = NetworkArchitecture(
            networkType: "actor",
            inputSize: 3,
            outputSize: 2,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: "tanh"
        )
        let criticArch = NetworkArchitecture(
            networkType: "qEnsemble",
            inputSize: 4,
            outputSize: 1,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        return try saveSACAgent(
            name: name,
            actor: actor,
            qEnsemble: qEnsemble,
            environmentType: .pendulum,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            alpha: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            networkArchitectures: [actorArch, criticArch]
        )
    }
    
    func updatePendulumAgent(
        id: UUID,
        newName: String,
        actor: Module,
        qEnsemble: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        try updateSACAgent(
            id: id,
            newName: newName,
            actor: actor,
            qEnsemble: qEnsemble,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            alpha: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters
        )
    }
    
    func loadPendulumWeights(for agent: SavedAgent) throws -> [String: [String: MLXArray]] {
        guard agent.environmentType == .pendulum else {
            throw AgentStorageError.wrongEnvironmentType
        }
        return try loadSACWeightsGeneric(for: agent)
    }
    
    func saveLunarLanderContinuousAgent(
        name: String,
        actor: Module,
        qEnsemble: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double],
        environmentConfig: [String: String],
        hiddenSize: Int = 256
    ) throws -> SavedAgent {
        let actorArch = NetworkArchitecture(
            networkType: "actor",
            inputSize: 8,
            outputSize: 4,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: "tanh"
        )
        let criticArch = NetworkArchitecture(
            networkType: "qEnsemble",
            inputSize: 10,
            outputSize: 1,
            hiddenSizes: [hiddenSize, hiddenSize],
            hiddenActivation: "relu",
            outputActivation: nil
        )
        
        return try saveSACAgent(
            name: name,
            actor: actor,
            qEnsemble: qEnsemble,
            environmentType: .lunarLanderContinuous,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            alpha: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters,
            environmentConfig: environmentConfig,
            networkArchitectures: [actorArch, criticArch]
        )
    }
    
    func updateLunarLanderContinuousAgent(
        id: UUID,
        newName: String,
        actor: Module,
        qEnsemble: Module,
        episodesTrained: Int,
        trainingTimeSeconds: Double? = nil,
        alpha: Double,
        bestReward: Double,
        averageReward: Double,
        hyperparameters: [String: Double]
    ) throws {
        try updateSACAgent(
            id: id,
            newName: newName,
            actor: actor,
            qEnsemble: qEnsemble,
            episodesTrained: episodesTrained,
            trainingTimeSeconds: trainingTimeSeconds,
            alpha: alpha,
            bestReward: bestReward,
            averageReward: averageReward,
            hyperparameters: hyperparameters
        )
    }
    
    func loadLunarLanderContinuousWeights(for agent: SavedAgent) throws -> [String: [String: MLXArray]] {
        guard agent.environmentType == .lunarLanderContinuous else {
            throw AgentStorageError.wrongEnvironmentType
        }
        return try loadSACWeightsGeneric(for: agent)
    }
    
    func loadAgent(id: UUID) throws -> SavedAgent {
        for envType in EnvironmentType.allCases {
            let envDir = agentsDirectory.appendingPathComponent(envType.displayName, isDirectory: true)
            guard fileManager.fileExists(atPath: envDir.path) else { continue }
            
            if let agentFolders = try? fileManager.contentsOfDirectory(at: envDir, includingPropertiesForKeys: nil) {
                for folder in agentFolders where folder.hasDirectoryPath {
                    let metadataPath = folder.appendingPathComponent("metadata.json")
                    if let data = try? Data(contentsOf: metadataPath),
                       let agent = try? decoder.decode(SavedAgent.self, from: data),
                       agent.id == id {
                        return agent
                    }
                }
            }
        }
        
        throw AgentStorageError.agentNotFound
    }
    
    private func renameAgentFolder(from oldFolder: URL, to newName: String, environmentType: EnvironmentType) throws -> URL {
        let envDir = environmentDirectory(for: environmentType)
        let sanitizedName = sanitizeFolderName(newName)
        var folderName = sanitizedName
        var counter = 1
        
        var newFolder = envDir.appendingPathComponent(folderName, isDirectory: true)
        while fileManager.fileExists(atPath: newFolder.path) && newFolder != oldFolder {
            folderName = "\(sanitizedName) (\(counter))"
            counter += 1
            newFolder = envDir.appendingPathComponent(folderName, isDirectory: true)
        }
        
        if newFolder != oldFolder {
            try fileManager.moveItem(at: oldFolder, to: newFolder)
        }
        
        return newFolder
    }
    
    func renameAgent(id: UUID, newName: String) throws {
        var agent = try loadAgent(id: id)
        let oldFolder = agentFolder(for: agent)
        
        let newFolder = try renameAgentFolder(from: oldFolder, to: newName, environmentType: agent.environmentType)
        
        let weightsFileName = URL(fileURLWithPath: agent.agentDataPath).lastPathComponent
        let envName = agent.environmentType.displayName
        let newDataPath = "\(envName)/\(newFolder.lastPathComponent)/\(weightsFileName)"
        
        agent.name = newName
        agent.updatedAt = Date()
        
        let updatedAgent = SavedAgent(
            id: agent.id,
            name: newName,
            environmentType: agent.environmentType,
            algorithmType: agent.algorithmType,
            createdAt: agent.createdAt,
            updatedAt: Date(),
            episodesTrained: agent.episodesTrained,
            trainingTimeSeconds: agent.trainingTimeSeconds,
            finalEpsilon: agent.finalEpsilon,
            bestReward: agent.bestReward,
            averageReward: agent.averageReward,
            successRate: agent.successRate,
            hyperparameters: agent.hyperparameters,
            environmentConfig: agent.environmentConfig,
            agentDataPath: newDataPath
        )
        
        let metadataPath = newFolder.appendingPathComponent("metadata.json")
        try encoder.encode(updatedAgent).write(to: metadataPath)
        
        loadAgentList()
    }
    
    func duplicateAgent(id: UUID) throws {
        let original = try loadAgent(id: id)
        let originalFolder = agentFolder(for: original)
        
        let newFolder = createAgentFolder(name: "\(original.name) Copy", environmentType: original.environmentType)
        let newId = UUID()
        let now = Date()
        
        let files = try fileManager.contentsOfDirectory(at: originalFolder, includingPropertiesForKeys: nil)
        for file in files {
            let destURL = newFolder.appendingPathComponent(file.lastPathComponent)
            if file.lastPathComponent != "metadata.json" {
                try fileManager.copyItem(at: file, to: destURL)
            }
        }
        
        let weightsFileName = URL(fileURLWithPath: original.agentDataPath).lastPathComponent
        let envName = original.environmentType.displayName
        let newDataPath = "\(envName)/\(newFolder.lastPathComponent)/\(weightsFileName)"
        
        let newAgent = SavedAgent(
            id: newId,
            name: "\(original.name) Copy",
            environmentType: original.environmentType,
            algorithmType: original.algorithmType,
            createdAt: now,
            updatedAt: now,
            episodesTrained: original.episodesTrained,
            trainingTimeSeconds: original.trainingTimeSeconds,
            finalEpsilon: original.finalEpsilon,
            bestReward: original.bestReward,
            averageReward: original.averageReward,
            successRate: original.successRate,
            hyperparameters: original.hyperparameters,
            environmentConfig: original.environmentConfig,
            agentDataPath: newDataPath
        )
        
        let metadataPath = newFolder.appendingPathComponent("metadata.json")
        try encoder.encode(newAgent).write(to: metadataPath)
        
        loadAgentList()
    }
    
    func deleteAgent(id: UUID) throws {
        let agent = try loadAgent(id: id)
        let folder = agentFolder(for: agent)
        
        try fileManager.removeItem(at: folder)
        
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

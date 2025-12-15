//
//  SavedAgentsImporter.swift
//

import Foundation

struct DiscoveredAgent: Sendable {
    let agent: SavedAgent
    let sourceFolder: URL
    let bookmarkData: Data?
}

private struct RawAgentData: Sendable {
    let metadataData: Data
    let sourceFolder: URL
    let bookmarkData: Data?
}

actor SavedAgentsImporterCache {
    static let shared = SavedAgentsImporterCache()
    private var cache: [DiscoveredAgent] = []
    
    func set(_ agents: [DiscoveredAgent]) {
        cache = agents
    }
    
    func get() -> [DiscoveredAgent] {
        cache
    }
    
    func find(id: UUID) -> DiscoveredAgent? {
        cache.first { $0.agent.id == id }
    }
}

enum SavedAgentsImporter {
    
    static func discoverAgents(in folder: URL) async throws -> [SavedAgent] {
        let folderCopy = folder
        
        let rawResults = try await Task.detached {
            try Self.performScan(folderCopy)
        }.value
        
        let discovered = try decodeRawResults(rawResults)
        
        await SavedAgentsImporterCache.shared.set(discovered)
        return discovered.map(\.agent)
    }
    
    private static func decodeRawResults(_ rawResults: [RawAgentData]) throws -> [DiscoveredAgent] {
        let decoder = JSONDecoder()
        var results: [DiscoveredAgent] = []
        
        for raw in rawResults {
            if let agent = try? decoder.decode(SavedAgent.self, from: raw.metadataData) {
                results.append(DiscoveredAgent(agent: agent, sourceFolder: raw.sourceFolder, bookmarkData: raw.bookmarkData))
            }
        }
        
        return results
    }
    
    nonisolated private static func performScan(_ folder: URL) throws -> [RawAgentData] {
        let fm = FileManager.default
        var results: [RawAgentData] = []
        
        if let rawData = try? loadRawAgentData(folder, fileManager: fm) {
            results.append(rawData)
            return results
        }
        
        guard let contents = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return results
        }
        
        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDir else { continue }
            
            if let rawData = try? loadRawAgentData(item, fileManager: fm) {
                results.append(rawData)
            } else {
                let nested = try performScan(item)
                results.append(contentsOf: nested)
            }
        }
        
        return results
    }
    
    nonisolated private static func loadRawAgentData(_ folder: URL, fileManager fm: FileManager) throws -> RawAgentData? {
        let metadataPath = folder.appendingPathComponent("metadata.json")
        guard fm.fileExists(atPath: metadataPath.path) else { return nil }
        
        let data = try Data(contentsOf: metadataPath)
        
        let contents = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        let hasWeights = contents.contains { url in
            let ext = url.pathExtension.lowercased()
            return ext == "safetensors" || ext == "npy"
        }
        
        guard hasWeights else { return nil }
        
        #if os(iOS)
        let bookmarkData = try? folder.bookmarkData(options: .minimalBookmark)
        #else
        let bookmarkData = try? folder.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
        #endif
        
        return RawAgentData(metadataData: data, sourceFolder: folder, bookmarkData: bookmarkData)
    }
    
    @MainActor
    static func importAgent(_ agent: SavedAgent) async throws {
        guard let discovered = await SavedAgentsImporterCache.shared.find(id: agent.id) else {
            throw ImportError.agentNotFound
        }
        
        var sourceFolder = discovered.sourceFolder
        var accessingSecurityScope = false
        
        if let bookmarkData = discovered.bookmarkData {
            var isStale = false
            #if os(iOS)
            if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale) {
                sourceFolder = resolvedURL
                accessingSecurityScope = resolvedURL.startAccessingSecurityScopedResource()
            }
            #else
            if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                sourceFolder = resolvedURL
                accessingSecurityScope = resolvedURL.startAccessingSecurityScopedResource()
            }
            #endif
        }
        
        defer {
            if accessingSecurityScope {
                sourceFolder.stopAccessingSecurityScopedResource()
            }
        }
        
        let targetRoot = AgentStorage.shared.agentsDirectoryURL
        let envFolder = targetRoot.appendingPathComponent(agent.environmentType.displayName, isDirectory: true)
        
        let fm = FileManager.default
        if !fm.fileExists(atPath: envFolder.path) {
            try fm.createDirectory(at: envFolder, withIntermediateDirectories: true)
        }
        
        var folderName = sanitizeFolderName(agent.name)
        var targetFolder = envFolder.appendingPathComponent(folderName, isDirectory: true)
        var counter = 1
        while fm.fileExists(atPath: targetFolder.path) {
            folderName = "\(sanitizeFolderName(agent.name)) (\(counter))"
            counter += 1
            targetFolder = envFolder.appendingPathComponent(folderName, isDirectory: true)
        }
        
        try fm.createDirectory(at: targetFolder, withIntermediateDirectories: true)
        
        let sourceContents = try fm.contentsOfDirectory(at: sourceFolder, includingPropertiesForKeys: nil)
        for item in sourceContents {
            let destPath = targetFolder.appendingPathComponent(item.lastPathComponent)
            try fm.copyItem(at: item, to: destPath)
        }
        
        let weightsFileName = getWeightsFileName(for: agent)
        let newDataPath = "\(agent.environmentType.displayName)/\(folderName)/\(weightsFileName)"
        
        var updatedAgent = agent
        let mirror = Mirror(reflecting: updatedAgent)
        if mirror.children.contains(where: { $0.label == "agentDataPath" }) {
            let encoder = JSONEncoder()
            var jsonData = try encoder.encode(agent)
            if var dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                dict["agentDataPath"] = newDataPath
                dict["name"] = folderName.replacingOccurrences(of: " (\\d+)$", with: "", options: .regularExpression)
                jsonData = try JSONSerialization.data(withJSONObject: dict)
                let decoder = JSONDecoder()
                updatedAgent = try decoder.decode(SavedAgent.self, from: jsonData)
            }
        }
        
        let newMetadataPath = targetFolder.appendingPathComponent("metadata.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let metadataData = try encoder.encode(updatedAgent)
        try metadataData.write(to: newMetadataPath)
    }
    
    private static func sanitizeFolderName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        var sanitized = name.components(separatedBy: invalidChars).joined(separator: "_")
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.isEmpty { sanitized = "Untitled" }
        return sanitized
    }
    
    private static func getWeightsFileName(for agent: SavedAgent) -> String {
        if agent.environmentType == .frozenLake {
            return "qtable.npy"
        }
        return "weights.safetensors"
    }
    
    enum ImportError: LocalizedError {
        case agentNotFound
        case copyFailed
        
        var errorDescription: String? {
            switch self {
            case .agentNotFound:
                return "Agent source folder not found"
            case .copyFailed:
                return "Failed to copy agent files"
            }
        }
    }
}

//
//  SessionStorage.swift
//  ExploreRL
//

import Foundation

final class SessionStorage: Sendable {

    static let shared = SessionStorage()

    nonisolated var sessionsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExploreRL", isDirectory: true)
            .appendingPathComponent("Sessions", isDirectory: true)
    }

    nonisolated func sessionDirectory(for id: UUID) -> URL {
        sessionsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    nonisolated func checkpointDirectory(for id: UUID) -> URL {
        sessionDirectory(for: id).appendingPathComponent("checkpoint", isDirectory: true)
    }

    func listSessions() -> [SavedSession] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: sessionsDirectory.path) else { return [] }
        guard let contents = try? fm.contentsOfDirectory(
            at: sessionsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return contents.compactMap { dir in
            let sessionFile = dir.appendingPathComponent("session.json")
            guard let data = try? Data(contentsOf: sessionFile) else { return nil }
            return try? decoder.decode(SavedSession.self, from: data)
        }
        .sorted { $0.savedAt > $1.savedAt }
    }

    func save(session: SavedSession) throws {
        let dir = sessionDirectory(for: session.id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: dir.appendingPathComponent("session.json"))
    }

    func delete(sessionID: UUID) throws {
        let dir = sessionDirectory(for: sessionID)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }

    func deleteAll() throws {
        let dir = sessionsDirectory
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }

    func sessionSize(for id: UUID) -> Int64 {
        let dir = sessionDirectory(for: id)
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}

import Foundation
import AppleArchive
import System
import UniformTypeIdentifiers
import CoreTransferable

struct SessionExport: Transferable {
    nonisolated static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .data) { _ in
            let url = try await MainActor.run {
                try SessionStorage.shared.exportAllSessions()
            }
            return SentTransferredFile(url)
        }
    }
}

extension SessionStorage {

    static let archiveContentType: UTType = .data

    var exportsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExploreRL", isDirectory: true)
            .appendingPathComponent("Exports", isDirectory: true)
    }

    func exportSession(_ session: SavedSession) throws -> URL {
        let source = sessionDirectory(for: session.id)
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try writeArchive(from: source, name: sanitize(session.name))
    }

    func exportAllSessions() throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
        return try writeArchive(from: sessionsDirectory, name: "ExploreRL-Sessions")
    }

    func importSessions(from url: URL) throws -> Int {
        let fm = FileManager.default
        let staging = fm.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }

        try extractArchive(at: url, to: staging)
        return try restoreSessions(from: staging)
    }
}

private extension SessionStorage {

    func writeArchive(from source: URL, name: String) throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)

        let destination = exportsDirectory
            .appendingPathComponent(name)
            .appendingPathExtension("xrlsession")

        guard let writeStream = ArchiveByteStream.fileStream(
            path: FilePath(destination.path),
            mode: .writeOnly,
            options: [.create, .truncate],
            permissions: FilePermissions(rawValue: 0o644)
        ) else { throw CocoaError(.fileWriteUnknown) }
        defer { try? writeStream.close() }

        guard let compressStream = ArchiveByteStream.compressionStream(
            using: .lzfse,
            writingTo: writeStream
        ) else { throw CocoaError(.fileWriteUnknown) }
        defer { try? compressStream.close() }

        guard let encodeStream = ArchiveStream.encodeStream(
            writingTo: compressStream
        ) else { throw CocoaError(.fileWriteUnknown) }
        defer { try? encodeStream.close() }

        guard let keySet = ArchiveHeader.FieldKeySet("TYP,PAT,DAT,MOD") else {
            throw CocoaError(.fileWriteUnknown)
        }

        try encodeStream.writeDirectoryContents(
            archiveFrom: FilePath(source.path),
            keySet: keySet
        )

        return destination
    }

    func extractArchive(at source: URL, to destination: URL) throws {
        guard let readStream = ArchiveByteStream.fileStream(
            path: FilePath(source.path),
            mode: .readOnly,
            options: [],
            permissions: FilePermissions(rawValue: 0o644)
        ) else { throw CocoaError(.fileReadUnknown) }
        defer { try? readStream.close() }

        guard let decompressStream = ArchiveByteStream.decompressionStream(
            readingFrom: readStream
        ) else { throw CocoaError(.fileReadCorruptFile) }
        defer { try? decompressStream.close() }

        guard let decodeStream = ArchiveStream.decodeStream(
            readingFrom: decompressStream
        ) else { throw CocoaError(.fileReadCorruptFile) }
        defer { try? decodeStream.close() }

        guard let extractStream = ArchiveStream.extractStream(
            extractingTo: FilePath(destination.path),
            flags: [.ignoreOperationNotPermitted]
        ) else { throw CocoaError(.fileReadUnknown) }
        defer { try? extractStream.close() }

        _ = try ArchiveStream.process(readingFrom: decodeStream, writingTo: extractStream)
    }

    func restoreSessions(from staging: URL) throws -> Int {
        let fm = FileManager.default
        let sessionFiles = findSessionFiles(under: staging)
        guard !sessionFiles.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }

        try fm.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var count = 0
        for jsonURL in sessionFiles {
            let sourceDir = jsonURL.deletingLastPathComponent()
            let data = try Data(contentsOf: jsonURL)
            let session = try decoder.decode(SavedSession.self, from: data)

            var targetID = session.id
            if fm.fileExists(atPath: sessionDirectory(for: targetID).path) {
                targetID = UUID()
            }

            let destination = sessionDirectory(for: targetID)

            if sourceDir.standardizedFileURL == staging.standardizedFileURL {
                try fm.createDirectory(at: destination, withIntermediateDirectories: true)
                for item in try fm.contentsOfDirectory(at: staging, includingPropertiesForKeys: nil) {
                    try fm.moveItem(
                        at: item,
                        to: destination.appendingPathComponent(item.lastPathComponent)
                    )
                }
            } else {
                try fm.moveItem(at: sourceDir, to: destination)
            }

            if targetID != session.id {
                let updated = SavedSession(
                    id: targetID,
                    name: session.name,
                    environmentID: session.environmentID,
                    algorithmType: session.algorithmType,
                    trainingConfig: session.trainingConfig,
                    trainingState: session.trainingState,
                    envSettings: session.envSettings,
                    savedAt: session.savedAt
                )
                try save(session: updated)
            }

            count += 1
        }

        return count
    }

    func findSessionFiles(under directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else { return [] }

        var results: [URL] = []
        for case let url as URL in enumerator where url.lastPathComponent == "session.json" {
            results.append(url)
        }
        return results
    }

    func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
            .union(.newlines).union(.controlCharacters)
        return name.components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

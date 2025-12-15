import Foundation

struct AgentExport: Identifiable, Hashable {
    let url: URL
    var id: URL { url }
    var name: String { url.lastPathComponent }
    var createdAt: Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var formattedSize: String {
        let size = Self.folderSize(at: url)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private static func folderSize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}

enum SavedAgentsExporter {
    private static var fileManager: FileManager { .default }
    
    private static var exportsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = documents.appendingPathComponent("SavedAgentsExports", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    static func listExports() -> [AgentExport] {
        guard let files = try? fileManager.contentsOfDirectory(at: exportsDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        return files
            .filter { $0.hasDirectoryPath || $0.pathExtension.lowercased() == "zip" }
            .map { AgentExport(url: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    static func createExport() throws -> AgentExport {
        let source = AgentStorage.shared.agentsDirectoryURL
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let folderName = "SavedAgents_\(formatter.string(from: Date()))"
        let destination = exportsDirectory.appendingPathComponent(folderName, isDirectory: true)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
        return AgentExport(url: destination)
    }
    
    static func deleteExport(_ export: AgentExport) throws {
        try fileManager.removeItem(at: export.url)
    }
}


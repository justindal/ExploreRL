import Foundation

@Observable
final class LibraryViewModel {

    var sessions: [SavedSession] = []
    var sessionSizes: [UUID: Int64] = [:]
    var deleteError: String?
    var transferError: String?
    var exportError: String?
    var lastImportedCount: Int?

    private let storage = SessionStorage.shared

    func loadSessions() {
        sessions = storage.listSessions()
        sessionSizes = [:]
        for session in sessions {
            sessionSizes[session.id] = storage.sessionSize(for: session.id)
        }
    }

    func importSessions(from urls: [URL]) {
        do {
            var imported = 0
            for url in urls {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                imported += try storage.importSessions(from: url)
            }
            transferError = nil
            lastImportedCount = imported
            loadSessions()
        } catch {
            lastImportedCount = nil
            transferError = error.localizedDescription
        }
    }

    func delete(session: SavedSession) {
        do {
            try storage.delete(sessionID: session.id)
            sessions.removeAll { $0.id == session.id }
            sessionSizes[session.id] = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }

    func deleteSessions(at offsets: IndexSet) {
        let toDelete = offsets.map { sessions[$0] }
        for session in toDelete {
            delete(session: session)
        }
    }

    func filteredSessions(matching query: String) -> [SavedSession] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sessions }

        let normalized = trimmed.lowercased()
        return sessions.filter { session in
            session.name.lowercased().contains(normalized)
                || session.environmentID.lowercased().contains(normalized)
                || session.algorithmType.rawValue.lowercased().contains(normalized)
        }
    }

    func deleteSessions(withIDs ids: [UUID]) {
        let sessionsToDelete = sessions.filter { ids.contains($0.id) }
        for session in sessionsToDelete {
            delete(session: session)
        }
    }

    func exportSession(_ session: SavedSession) throws -> URL {
        try storage.exportSession(session)
    }
}

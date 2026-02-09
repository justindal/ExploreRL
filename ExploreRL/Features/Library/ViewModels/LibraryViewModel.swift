import Foundation

@Observable
final class LibraryViewModel {

    var sessions: [SavedSession] = []
    var sessionSizes: [UUID: Int64] = [:]
    var deleteError: String?
    var transferError: String?
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
}

import Foundation

enum SortOrder: String, CaseIterable, Identifiable {
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"
    case rewardDesc = "Best Reward"
    case nameAsc = "Name"

    var id: String { rawValue }
}

enum AlgorithmFilter: String, CaseIterable, Identifiable {
    case qLearning = "Q-Learning"
    case sarsa = "SARSA"
    case dqn = "DQN"
    case ppo = "PPO"
    case sac = "SAC"
    case td3 = "TD3"

    var id: String { rawValue }
}

@Observable
final class LibraryViewModel {

    var sessions: [SavedSession] = []
    var deleteError: String?
    var renameError: String?
    var transferError: String?
    var exportError: String?
    var lastImportedCount: Int?
    var sortOrder: SortOrder = .dateDesc
    var algorithmFilters: Set<AlgorithmFilter> = []

    private let storage = SessionStorage.shared

    func loadSessions() {
        sessions = storage.listSessions()
    }

    func importSessions(from urls: [URL]) {
        do {
            var imported = 0
            for url in urls {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                imported += try storage.importSessions(from: url)
            }
            storage.invalidateExportCache()
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
            storage.invalidateExportCache()
            sessions.removeAll { $0.id == session.id }
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

    func sortedAndFilteredSessions(matching query: String) -> [SavedSession] {
        let filtered = filter(sessions, matching: query)
        return sort(filtered)
    }

    func groupedSessions(matching query: String) -> [(envID: String, sessions: [SavedSession])] {
        let sorted = sortedAndFilteredSessions(matching: query)
        let grouped = Dictionary(grouping: sorted, by: \.environmentID)
        return grouped.keys.sorted().map { key in
            (envID: key, sessions: grouped[key] ?? [])
        }
    }

    func deleteSessions(withIDs ids: [UUID]) {
        let toDelete = sessions.filter { ids.contains($0.id) }
        for session in toDelete {
            delete(session: session)
        }
    }

    func rename(sessionID: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            renameError = "Session name cannot be empty."
            return
        }
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else {
            return
        }

        let session = sessions[index]
        let updated = SavedSession(
            id: session.id,
            name: trimmed,
            environmentID: session.environmentID,
            algorithmType: session.algorithmType,
            trainingConfig: session.trainingConfig,
            trainingState: session.trainingState,
            envSettings: session.envSettings,
            savedAt: session.savedAt
        )

        do {
            try storage.save(session: updated)
            storage.invalidateExportCache()
            sessions[index] = updated
            renameError = nil
        } catch {
            renameError = error.localizedDescription
        }
    }

    func exportSession(_ session: SavedSession) throws -> URL {
        try storage.exportSession(session)
    }

    private func filter(_ list: [SavedSession], matching query: String) -> [SavedSession] {
        var result = list

        if !algorithmFilters.isEmpty {
            let selectedRawValues = Set(algorithmFilters.map { $0.rawValue })
            result = result.filter { selectedRawValues.contains($0.algorithmType.rawValue) }
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return result }
        let normalized = trimmed.lowercased()
        return result.filter { session in
            session.name.lowercased().contains(normalized)
                || session.environmentID.lowercased().contains(normalized)
                || session.algorithmType.rawValue.lowercased().contains(normalized)
        }
    }

    private func sort(_ list: [SavedSession]) -> [SavedSession] {
        switch sortOrder {
        case .dateDesc:
            return list.sorted { $0.savedAt > $1.savedAt }
        case .dateAsc:
            return list.sorted { $0.savedAt < $1.savedAt }
        case .rewardDesc:
            return list.sorted {
                ($0.trainingState.meanReward ?? -.infinity) > ($1.trainingState.meanReward ?? -.infinity)
            }
        case .nameAsc:
            return list.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
}

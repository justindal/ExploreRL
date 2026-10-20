import Foundation

extension SessionStorage {
    func snapshotDirectory(for id: UUID) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ExploreRL-TrainingSnapshots", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
    }

    func discard(_ snapshot: TrainingSnapshot) {
        try? FileManager.default.removeItem(at: snapshot.directory)
    }

    func saveSnapshot(_ snapshot: TrainingSnapshot, name: String) throws -> SavedSession {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw TrainError.invalidConfiguration("Enter a session name.") }
        let source = snapshot.session
        let session = SavedSession(
            id: UUID(), name: name, environmentID: source.environmentID, algorithmType: source.algorithmType,
            trainingConfig: source.trainingConfig, trainingState: source.trainingState,
            envSettings: source.envSettings, savedAt: .now,
            observationVersion: source.observationVersion, activeTrainingSeconds: source.activeTrainingSeconds, timingStartTimestep: source.timingStartTimestep
        )
        do {
            try FileManager.default.createDirectory(at: sessionDirectory(for: session.id), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: snapshot.checkpointDirectory, to: checkpointDirectory(for: session.id))
            try save(session: session)
            invalidateExportCache()
            return session
        } catch {
            try? delete(sessionID: session.id)
            throw error
        }
    }
}

import Foundation

struct TrainingSnapshot: Identifiable {
    let session: SavedSession
    let directory: URL

    var id: UUID { session.id }
    var checkpointDirectory: URL { directory.appendingPathComponent("checkpoint", isDirectory: true) }
}

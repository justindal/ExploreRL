import Foundation
import Gymnazo

enum SessionCompatibility {
    static func validate(_ session: SavedSession) throws {
        if session.environmentID == MetroRunnerSettings.id,
            session.observationVersion != MetroRunnerObservation.version {
            throw SessionCompatibilityError.metroObservationChanged
        }
    }
}

enum SessionCompatibilityError: LocalizedError {
    case metroObservationChanged

    var errorDescription: String? {
        "Metro Run now uses observation version \(MetroRunnerObservation.version) with \(MetroRunnerObservation.flatCount) inputs. This agent uses an earlier or unsupported format. Train a new agent with the updated environment."
    }
}

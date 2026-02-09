import Foundation
import Synchronization

final class TrainingAccumulator: Sendable {

    struct Pending: @unchecked Sendable {
        var timestep: Int = 0
        var explorationRate: Double = 0
        var episodes: [(Double, Int)] = []
        var metrics: [[String: Double]] = []
        var renderSnapshot: (any Sendable)?
    }

    private let state = Mutex(Pending())

    nonisolated func recordStep(timestep: Int, explorationRate: Double) {
        state.withLock {
            $0.timestep = timestep
            $0.explorationRate = explorationRate
        }
    }

    nonisolated func recordEpisode(reward: Double, length: Int) {
        state.withLock {
            $0.episodes.append((reward, length))
        }
    }

    nonisolated func recordMetrics(_ metrics: [String: Double]) {
        state.withLock {
            $0.metrics.append(metrics)
        }
    }

    nonisolated func recordSnapshot(_ snapshot: any Sendable) {
        state.withLock {
            $0.renderSnapshot = snapshot
        }
    }

    nonisolated func drain() -> Pending {
        state.withLock {
            let current = $0
            $0.episodes = []
            $0.metrics = []
            $0.renderSnapshot = nil
            return current
        }
    }

    nonisolated func reset() {
        state.withLock { $0 = Pending() }
    }
}

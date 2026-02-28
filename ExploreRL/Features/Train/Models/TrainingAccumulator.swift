import Foundation
import Synchronization

final class TrainingAccumulator: Sendable {

    struct Pending: @unchecked Sendable {
        var timestep: Int = 0
        var explorationRate: Double?
        var episodes: [(timestep: Int, reward: Double, length: Int)] = []
        var metrics: [(timestep: Int, values: [String: Double])] = []
        var renderSnapshot: (any Sendable)?
    }

    private let state = Mutex(Pending())

    nonisolated func recordStep(timestep: Int, explorationRate: Double?) {
        state.withLock {
            $0.timestep = timestep
            if let explorationRate, explorationRate.isFinite {
                $0.explorationRate = explorationRate
            } else {
                $0.explorationRate = nil
            }
        }
    }

    nonisolated func recordEpisode(reward: Double, length: Int) {
        state.withLock {
            let timestep = max(0, $0.timestep + 1)
            $0.episodes.append((timestep: timestep, reward: reward, length: length))
        }
    }

    nonisolated func recordMetrics(_ metrics: [String: Double]) {
        state.withLock {
            let finite = metrics.filter { $0.value.isFinite }
            if !finite.isEmpty {
                $0.metrics.append((timestep: max(0, $0.timestep), values: finite))
            }
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

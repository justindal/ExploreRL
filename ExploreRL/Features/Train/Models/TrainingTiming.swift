import Foundation

struct TrainingTiming: Sendable, Equatable {
    var startedAt: Date
    var pausedAt: Date?
    var pausedDuration: TimeInterval
    var initialTimestep: Int
    var previousElapsed: TimeInterval

    init(startedAt: Date, initialTimestep: Int = 0, previousElapsed: TimeInterval = 0) {
        self.startedAt = startedAt
        self.pausedAt = nil
        self.pausedDuration = 0
        self.initialTimestep = initialTimestep
        self.previousElapsed = previousElapsed
    }

    mutating func pause(at date: Date) {
        guard pausedAt == nil else { return }
        pausedAt = date
    }

    mutating func resume(at date: Date) {
        if let pausedAt {
            pausedDuration += date.timeIntervalSince(pausedAt)
        }
        pausedAt = nil
    }

    func activeElapsed(now: Date) -> TimeInterval {
        let pausedNow = pausedAt.map { now.timeIntervalSince($0) } ?? 0
        return max(0, previousElapsed + now.timeIntervalSince(startedAt) - pausedDuration - pausedNow)
    }
}

import Foundation

struct TrainingTiming: Sendable, Equatable {
    var startedAt: Date
    var pausedAt: Date?
    var pausedDuration: TimeInterval

    init(startedAt: Date) {
        self.startedAt = startedAt
        self.pausedAt = nil
        self.pausedDuration = 0
    }

    mutating func pause(at date: Date) {
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
        return max(0, now.timeIntervalSince(startedAt) - pausedDuration - pausedNow)
    }
}


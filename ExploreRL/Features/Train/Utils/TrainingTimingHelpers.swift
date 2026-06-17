import Foundation

func stepsPerMin(timesteps: Int, elapsed: TimeInterval) -> Double {
    guard elapsed > 0 else { return 0 }
    return Double(timesteps) / (elapsed / 60.0)
}

func etaSeconds(
    stepsPerMinute: Double,
    currentTimestep: Int,
    totalTimesteps: Int
) -> TimeInterval? {
    guard stepsPerMinute > 0 else { return nil }
    let remaining = max(0, totalTimesteps - currentTimestep)
    return (Double(remaining) / stepsPerMinute) * 60.0
}

func formatTime(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded()))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
}

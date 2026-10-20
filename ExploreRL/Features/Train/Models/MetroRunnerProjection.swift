import CoreGraphics

nonisolated struct MetroRunnerProjection {
    let runnerX: Double
    let runnerY: Double

    func point(x: Double, y: Double, distance: Double) -> CGPoint {
        let scale = scale(at: distance)
        return CGPoint(x: 360 + (x - runnerX * 0.18) * scale,
                       y: 110 + (48 + runnerY * 0.72 - y) * scale)
    }

    func scale(at distance: Double) -> Double {
        590 / max(30, distance + 95)
    }
}

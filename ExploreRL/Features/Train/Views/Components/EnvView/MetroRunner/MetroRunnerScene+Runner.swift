import Gymnazo
import SwiftUI

extension MetroRunnerScene {
    nonisolated func drawRunner(in context: GraphicsContext) {
        let projection = MetroRunnerProjection(runnerX: snapshot.x, runnerY: snapshot.y)
        let foot = projection.point(x: snapshot.x, y: snapshot.y, distance: 0)
        let shadow = projection.point(x: snapshot.x, y: snapshot.surface, distance: 0)
        let scale = projection.scale(at: 0)
        let unit = scale / 6
        context.fill(Path(ellipseIn: CGRect(x: shadow.x - 19 * unit, y: shadow.y - 4 * unit, width: 38 * unit, height: 8 * unit)), with: .color(.black.opacity(0.35)))
        if snapshot.boardRemaining > 0 {
            context.fill(Path(ellipseIn: CGRect(x: foot.x - 25 * unit, y: foot.y - 3 * unit, width: 50 * unit, height: 8 * unit)), with: .color(.mint))
        }
        if snapshot.powers[.jetpack, default: 0] > 0 {
            for side in [-1.0, 1] {
                let x = foot.x + side * 12 * unit
                let flame = Path { path in
                    path.move(to: CGPoint(x: x - 4 * unit, y: foot.y - 20 * unit))
                    path.addLine(to: CGPoint(x: x + 4 * unit, y: foot.y - 20 * unit))
                    path.addLine(to: CGPoint(x: x, y: foot.y + 10 * unit))
                    path.closeSubpath()
                }
                context.fill(flame, with: .color(.orange))
            }
        }
        if snapshot.rolling {
            context.fill(Path(ellipseIn: CGRect(x: foot.x - 17 * unit, y: foot.y - 24 * unit, width: 34 * unit, height: 24 * unit)), with: .color(.yellow))
            return
        }
        let stride = snapshot.grounded ? sin(snapshot.distance * 0.12) * 6 * unit : 0
        let legs = Path { path in
            path.move(to: CGPoint(x: foot.x, y: foot.y - 24 * unit))
            path.addLine(to: CGPoint(x: foot.x - 7 * unit - stride, y: foot.y - 2 * unit))
            path.move(to: CGPoint(x: foot.x, y: foot.y - 24 * unit))
            path.addLine(to: CGPoint(x: foot.x + 7 * unit + stride, y: foot.y - 2 * unit))
        }
        context.stroke(legs, with: .color(Color(red: 0.12, green: 0.24, blue: 0.33)), style: StrokeStyle(lineWidth: 7 * unit, lineCap: .round))
        context.fill(Path(roundedRect: CGRect(x: foot.x - 11 * unit, y: foot.y - 43 * unit, width: 22 * unit, height: 24 * unit), cornerRadius: 6 * unit), with: .color(snapshot.dead ? .orange : .yellow))
        context.fill(Path(ellipseIn: CGRect(x: foot.x - 8 * unit, y: foot.y - 57 * unit, width: 16 * unit, height: 17 * unit)), with: .color(Color(red: 0.86, green: 0.62, blue: 0.45)))
        context.fill(Path(roundedRect: CGRect(x: foot.x - 10 * unit, y: foot.y - 60 * unit, width: 22 * unit, height: 7 * unit), cornerRadius: 3 * unit), with: .color(Color(red: 0.73, green: 0.22, blue: 0.18)))
    }
}

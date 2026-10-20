import Gymnazo
import SwiftUI

nonisolated struct MetroRunnerScene {
    let snapshot: MetroRunnerSnapshot
    private var projection: MetroRunnerProjection {
        MetroRunnerProjection(runnerX: snapshot.x, runnerY: snapshot.y)
    }

    func draw(in context: GraphicsContext) {
        context.fill(Path(CGRect(x: 0, y: 0, width: 720, height: 500)), with: .color(Color(red: 0.64, green: 0.77, blue: 0.8)))
        drawTrack(in: context)
        drawCity(in: context)
        let visible = snapshot.entities.filter {
            $0.z + $0.depth > snapshot.distance - 65 && $0.z < snapshot.distance + 700
        }.sorted { $0.z + $0.depth * 0.4 > $1.z + $1.depth * 0.4 }
        for entity in visible where !isForeground(entity) { draw(entity, in: context) }
        drawRunner(in: context)
        for entity in visible where isForeground(entity) { draw(entity, in: context) }
    }

    private func isForeground(_ entity: MetroRunnerEntitySnapshot) -> Bool {
        let support = [.train, .movingTrain, .ramp, .platform].contains(entity.kind)
        let overlaps = entity.z <= snapshot.distance && entity.z + entity.depth >= snapshot.distance
        return entity.z < snapshot.distance && !(support && overlaps)
    }

    private func drawTrack(in context: GraphicsContext) {
        polygon([(-500, -1, -65), (500, -1, -65), (500, -1, 800), (-500, -1, 800)], color: Color(white: 0.49), in: context)
        polygon([(-36, 0, -65), (36, 0, -65), (36, 0, 800), (-36, 0, 800)], color: Color(red: 0.19, green: 0.24, blue: 0.26), in: context)
        let first = Int((snapshot.distance - 65) / 20) * 20
        for absolute in stride(from: first + 800, through: first, by: -20) {
            let z = Double(absolute) - snapshot.distance
            for lane in [-20.0, 0, 20] {
                polygon([(lane - 8, 0.1, z), (lane + 8, 0.1, z), (lane + 8, 0.1, z + 2), (lane - 8, 0.1, z + 2)],
                        color: Color(red: 0.4, green: 0.38, blue: 0.34), in: context)
            }
        }
        for lane in [-20.0, 0, 20] {
            for edge in [-5.5, 5.5] {
                let x = lane + edge
                polygon([(x - 0.4, 0.3, -65), (x + 0.4, 0.3, -65), (x + 0.4, 0.3, 800), (x - 0.4, 0.3, 800)],
                        color: Color(white: 0.72), in: context)
            }
        }
    }

    private func drawCity(in context: GraphicsContext) {
        let first = Int(snapshot.distance / 160) * 160
        for absolute in stride(from: first + 800, through: first, by: -160) {
            let z = Double(absolute) - snapshot.distance
            for side in [-1.0, 1] {
                let index = abs(absolute / 160 + Int(side) * 19)
                let color = index % 2 == 0 ? Color(red: 0.68, green: 0.58, blue: 0.47) : Color(red: 0.47, green: 0.57, blue: 0.59)
                box(x: side * 90, y: 0, z: z, width: 52, height: Double(45 + index * 17 % 45), depth: 95, color: color, in: context)
            }
        }
    }

    private func draw(_ entity: MetroRunnerEntitySnapshot, in context: GraphicsContext) {
        let z = entity.z - snapshot.distance
        switch entity.kind {
        case .train, .movingTrain, .platform:
            let color: Color = entity.kind == .movingTrain ? Color(red: 0.74, green: 0.3, blue: 0.23)
                : entity.kind == .train ? Color(red: 0.23, green: 0.48, blue: 0.55) : Color(white: 0.5)
            box(x: entity.x, y: entity.y, z: z, width: entity.width, height: entity.height, depth: entity.depth, color: color, in: context)
            if entity.kind != .platform, z >= -30 {
                let left = entity.x - entity.width * 0.34, right = entity.x + entity.width * 0.34
                let bottom = entity.y + entity.height * 0.55, top = entity.y + entity.height * 0.82
                polygon([(left, bottom, z - 0.1), (right, bottom, z - 0.1), (right, top, z - 0.1), (left, top, z - 0.1)], color: Color(white: 0.15), in: context)
                if entity.kind == .movingTrain { symbol("exclamationmark", x: entity.x, y: entity.y + 10, z: z - 0.2, in: context) }
            }
        case .ramp:
            let run = entity.rampRun > 0 ? entity.rampRun : entity.depth
            let left = entity.x - entity.width / 2, right = entity.x + entity.width / 2
            polygon([(left, entity.y, z), (right, entity.y, z), (right, entity.y + entity.height, z + run), (left, entity.y + entity.height, z + run)],
                    color: Color(red: 0.68, green: 0.57, blue: 0.36), in: context)
            polygon([(left, entity.y + entity.height, z + run), (right, entity.y + entity.height, z + run),
                     (right, entity.y + entity.height, z + entity.depth), (left, entity.y + entity.height, z + entity.depth)],
                    color: Color(red: 0.76, green: 0.66, blue: 0.45), in: context)
        case .jump, .roll, .gate:
            let bottom = entity.kind == .roll ? entity.y + 5 : entity.y
            let height = entity.kind == .roll ? entity.height - 5 : entity.height
            box(x: entity.x, y: bottom, z: z, width: entity.width, height: height, depth: entity.depth,
                color: entity.kind == .gate ? Color(white: 0.43) : Color(red: 0.85, green: 0.46, blue: 0.18), in: context)
            if entity.kind == .jump || entity.kind == .roll {
                symbol(entity.kind == .jump ? "arrow.up" : "arrow.down", x: entity.x, y: bottom + height / 2, z: z - 0.2, in: context)
            }
        default:
            let center = projection.point(x: entity.x, y: entity.y + entity.height / 2, distance: z)
            let radius = max(1.5, projection.scale(at: z) * (entity.kind == .coin ? 1.8 : 3))
            let bounds = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: bounds), with: .color(entity.kind == .coin ? .yellow : .mint))
            if entity.kind != .coin { symbol(pickupSymbol(entity.kind), x: entity.x, y: entity.y + entity.height / 2, z: z, in: context) }
        }
    }

    private func pickupSymbol(_ kind: MetroRunnerEntityKind) -> String {
        switch kind {
        case .magnet: "u.circle.fill"
        case .sneakers: "shoe.fill"
        case .multiplier: "2.circle.fill"
        case .jetpack: "flame.fill"
        case .key: "key.fill"
        default: "questionmark"
        }
    }

    private func box(x: Double, y: Double, z: Double, width: Double, height: Double, depth: Double, color: Color, in context: GraphicsContext) {
        let near = max(-65, z), far = min(800, z + depth)
        guard far > near else { return }
        let left = x - width / 2, right = x + width / 2, top = y + height
        polygon([(left, y, near), (left, y, far), (left, top, far), (left, top, near)], color: color, in: context)
        polygon([(right, y, near), (right, y, far), (right, top, far), (right, top, near)], color: color.opacity(0.8), in: context)
        polygon([(left, top, near), (right, top, near), (right, top, far), (left, top, far)], color: color.mix(with: .white, by: 0.22), in: context)
        polygon([(left, y, near), (right, y, near), (right, top, near), (left, top, near)], color: color.mix(with: .black, by: 0.12), in: context)
    }

    private func polygon(_ points: [(Double, Double, Double)], color: Color, in context: GraphicsContext) {
        let vertices = points.map { projection.point(x: $0.0, y: $0.1, distance: $0.2) }
        let path = Path { path in
            path.addLines(vertices)
            path.closeSubpath()
        }
        context.fill(path, with: .color(color))
    }

    private func symbol(_ name: String, x: Double, y: Double, z: Double, in context: GraphicsContext) {
        let size = max(5, min(30, projection.scale(at: z) * 5))
        var image = context.resolve(Image(systemName: name))
        image.shading = .color(.white)
        let point = projection.point(x: x, y: y, distance: z)
        context.draw(image, in: CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size))
    }
}

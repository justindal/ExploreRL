import Gymnazo
import SwiftUI

struct MetroRunnerView: View {
    let snapshot: MetroRunnerSnapshot

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 720, y: size.height / 500)
            MetroRunnerScene(snapshot: snapshot).draw(in: context)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Metro Run simulation")
        .accessibilityValue("Lane \(Int((snapshot.x / 20 + 1).rounded()) + 1), distance \(Int(snapshot.distance)), \(snapshot.coins) coins, \(snapshot.dead ? "crashed" : "running")")
    }
}

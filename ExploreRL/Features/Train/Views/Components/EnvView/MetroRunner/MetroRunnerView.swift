import Gymnazo
import SwiftUI

struct MetroRunnerView: View {
    let snapshot: MetroRunnerSnapshot

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 720, y: size.height / 500)
            MetroRunnerScene(snapshot: snapshot).draw(in: context)
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 20) {
                LabeledContent("Distance", value: "\(Int(snapshot.distance))")
                LabeledContent("Coins", value: "\(snapshot.coins)")
                LabeledContent("Boards", value: "\(snapshot.boards)")
                Spacer(minLength: 0)
                if snapshot.dead {
                    Label("Crashed", systemImage: "exclamationmark.circle.fill")
                } else if snapshot.boardRemaining > 0 {
                    Label("Shield", systemImage: "shield.fill")
                }
            }
            .labeledContentStyle(.automatic)
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(.white)
            .padding(12)
            .background(.black.opacity(0.65))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Metro Run simulation")
        .accessibilityValue("Lane \(Int((snapshot.x / 20 + 1).rounded()) + 1), distance \(Int(snapshot.distance)), \(snapshot.coins) coins, \(snapshot.dead ? "crashed" : "running")")
    }
}

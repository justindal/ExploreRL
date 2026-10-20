import Gymnazo
import SwiftUI

struct MetroRunnerHUD: View {
    let snapshot: MetroRunnerSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                metrics
                status
            }
            .fixedSize()

            VStack(alignment: .leading, spacing: 4) {
                metrics
                status
            }
        }
        .font(.caption.monospacedDigit().weight(.semibold))
        .foregroundStyle(.white)
        .padding(8)
        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
        .padding(8)
        .accessibilityHidden(true)
    }

    private var metrics: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Text("Distance \(Int(snapshot.distance))")
            Text("Coins \(snapshot.coins)")
        }
    }

    @ViewBuilder
    private var status: some View {
        if snapshot.dead {
            Label("Crashed", systemImage: "exclamationmark.circle.fill")
        } else if snapshot.pogo {
            Label("Pogo", systemImage: "arrow.up.circle.fill")
        }
    }
}

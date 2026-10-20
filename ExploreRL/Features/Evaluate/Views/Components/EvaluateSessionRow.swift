import SwiftUI

struct EvaluateSessionRow: View {
    let session: SavedSession
    let onEvaluate: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: onEvaluate) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 12))
            layout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                    Text(session.environmentID)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let metricsLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                        : AnyLayout(HStackLayout(spacing: 8))
                    metricsLayout {
                        if let reward = session.trainingState.meanReward {
                            Label(
                                reward.formatted(.number.precision(.fractionLength(2))),
                                systemImage: "star.fill"
                            )
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(.orange)
                        }

                        Label(
                            "\(session.trainingState.currentTimestep.formatted()) steps",
                            systemImage: "figure.walk"
                        )
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                    }
                }

                if !dynamicTypeSize.isAccessibilitySize { Spacer() }

                AlgorithmBadge(text: session.algorithmType.rawValue)
                    .font(.caption2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .accessibilityHint("Opens evaluation settings")
        .swipeActions(edge: .trailing) {
            Button {
                onEvaluate()
            } label: {
                Label("Evaluate", systemImage: "play.fill")
            }
            .tint(.green)
        }
        .contextMenu {
            Button {
                onEvaluate()
            } label: {
                Label("Evaluate", systemImage: "play.fill")
            }
        }
    }
}

import SwiftUI

struct EvaluateSessionRow: View {
    let session: SavedSession
    let onEvaluate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                Text(session.environmentID)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    if let reward = session.trainingState.meanReward {
                        Label(
                            reward.formatted(.number.precision(.fractionLength(2))),
                            systemImage: "star.fill"
                        )
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }

                    Label(
                        "\(session.trainingState.currentTimestep.formatted()) steps",
                        systemImage: "figure.walk"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            AlgorithmBadge(text: session.algorithmType.rawValue)
                .font(.caption2)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEvaluate()
        }
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

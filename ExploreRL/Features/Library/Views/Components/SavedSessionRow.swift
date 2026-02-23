import SwiftUI

struct SavedSessionRow: View {
    let session: SavedSession
    var size: Int64?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                AlgorithmBadge(text: session.algorithmType.rawValue)
            }

            HStack(spacing: 12) {
                Text(session.environmentID)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let size {
                    Text(size.formatted(.byteCount(style: .file)))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(session.savedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(metricsText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var metricsText: String {
        var parts: [String] = []
        if let reward = session.trainingState.meanReward {
            parts.append("reward \(reward.formatted(.number.precision(.fractionLength(2))))")
        }
        parts.append("\(session.trainingState.currentTimestep.formatted()) steps")
        parts.append("\(session.trainingState.episodeCount.formatted()) eps")
        return parts.joined(separator: " · ")
    }
}

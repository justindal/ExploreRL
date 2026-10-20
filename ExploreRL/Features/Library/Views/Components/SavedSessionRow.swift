import SwiftUI

struct SavedSessionRow: View {
    let session: SavedSession
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.name)
                .font(.body.weight(.semibold))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

            Text(metricsText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                : AnyLayout(HStackLayout(spacing: 6))
            layout {
                EnvironmentBadge(text: session.environmentID)
                AlgorithmBadge(text: session.algorithmType.rawValue)
            }
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

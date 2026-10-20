import SwiftUI

struct EvaluationSummaryCard: View {
    let state: EvaluationState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(state.status.summaryTitle, systemImage: state.status.summarySymbol)
                .font(.headline)
                .foregroundStyle(statusColor)

            LazyVGrid(
                columns: dynamicTypeSize.isAccessibilitySize
                    ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 140))],
                alignment: .leading,
                spacing: 12
            ) {
                MetricCard(title: "Mean Reward", value: statistic(state.meanReward, deviation: state.stdReward))
                MetricCard(title: "Best Reward", value: state.episodeRewards.max()?.formatted(.number.precision(.fractionLength(2))) ?? "—")
                MetricCard(title: "Mean Length", value: statistic(state.meanLength, deviation: state.stdLength))
                MetricCard(title: "Episodes", value: state.episodeRewards.count.formatted())
            }
        }
        .padding(AppLayout.panelPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius))
    }

    private var statusColor: Color {
        switch state.status {
        case .completed: .green
        case .failed: .red
        default: .primary
        }
    }

    private func statistic(_ mean: Double?, deviation: Double?) -> String {
        guard let mean else { return "—" }
        let value = mean.formatted(.number.precision(.fractionLength(2)))
        guard let deviation else { return value }
        return "\(value) ± \(deviation.formatted(.number.precision(.fractionLength(2))))"
    }
}

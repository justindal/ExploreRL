import SwiftUI

struct EvaluationResults: View {
    let state: EvaluationState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Results")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            summarySection
            
            Divider()
                .padding(.vertical, 4)
            
            episodesSection
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var summarySection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: 16
        ) {
            statView(title: "Mean Reward", value: formatStat(mean: state.meanReward, std: state.stdReward))
            statView(title: "Mean Length", value: formatStat(mean: state.meanLength, std: state.stdLength))
            statView(title: "Best Reward", value: state.episodeRewards.max().map { String(format: "%.2f", $0) } ?? "-")
            statView(title: "Episodes", value: "\(state.episodeRewards.count)")
        }
    }

    @ViewBuilder
    private func statView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Per Episode")
                .font(.headline)

            HStack {
                Text("#").frame(width: 40, alignment: .leading)
                Text("Reward").frame(maxWidth: .infinity, alignment: .leading)
                Text("Length").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)

            ForEach(Array(state.episodeRewards.enumerated()), id: \.offset) { index, reward in
                HStack {
                    Text("\(index + 1)")
                        .frame(width: 40, alignment: .leading)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.2f", reward))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if index < state.episodeLengths.count {
                        Text("\(state.episodeLengths[index])")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Spacer()
                    }
                }
                .font(.subheadline.monospacedDigit())
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                
                if index < state.episodeRewards.count - 1 {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
    }

    private func formatStat(mean: Double?, std: Double?) -> String {
        guard let mean else { return "-" }
        let meanStr = String(format: "%.2f", mean)
        if let std {
            return "\(meanStr) ± \(String(format: "%.2f", std))"
        }
        return meanStr
    }
}

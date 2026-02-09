//
//  EvaluationResults.swift
//  ExploreRL
//

import SwiftUI

struct EvaluationResults: View {
    let state: EvaluationState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            summarySection
            episodesSection
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120))],
                spacing: 12
            ) {
                MetricCard(
                    title: "Mean Reward",
                    value: formatStat(mean: state.meanReward, std: state.stdReward)
                )
                MetricCard(
                    title: "Mean Length",
                    value: formatStat(mean: state.meanLength, std: state.stdLength)
                )
                MetricCard(
                    title: "Best Reward",
                    value: state.episodeRewards.max().map { String(format: "%.2f", $0) } ?? "-"
                )
                MetricCard(
                    title: "Episodes",
                    value: "\(state.episodeRewards.count)"
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per Episode")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(minimum: 40, maximum: 60)),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                alignment: .leading,
                spacing: 6
            ) {
                Text("#").font(.caption).foregroundStyle(.secondary)
                Text("Reward").font(.caption).foregroundStyle(.secondary)
                Text("Length").font(.caption).foregroundStyle(.secondary)

                ForEach(Array(state.episodeRewards.enumerated()), id: \.offset) { index, reward in
                    Text("\(index + 1)")
                        .monospacedDigit()
                        .font(.subheadline)
                    Text(String(format: "%.2f", reward))
                        .monospacedDigit()
                        .font(.subheadline)
                    if index < state.episodeLengths.count {
                        Text("\(state.episodeLengths[index])")
                            .monospacedDigit()
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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

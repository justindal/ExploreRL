//
//  MountainCarChartsView.swift
//

import SwiftUI

struct MountainCarChartsView: View {
    var runner: MountainCarRunner
    var columns: [GridItem] = []
    
    var body: some View {
        LazyVGrid(columns: columns.isEmpty ? [GridItem(.flexible())] : columns, spacing: 10) {
            MetricChart(
                title: "Episode Rewards",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .blue,
                averageValue: runner.episodeMetrics.suffix(50).map { $0.reward }.reduce(0, +) / max(1, Double(runner.episodeMetrics.suffix(50).count))
            )
            
            MetricChart(
                title: "Steps (Duration)",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { Double($0.steps) },
                color: .orange,
                averageValue: nil
            )
            
            MetricChart(
                title: "Loss",
                data: Array(runner.episodeMetrics.suffix(500).filter { $0.averageLoss != nil }),
                xValue: { $0.episode },
                yValue: { $0.averageLoss ?? 0 },
                color: .red,
                averageValue: nil
            )
            
            MetricChart(
                title: "Max Q-Value",
                data: Array(runner.episodeMetrics.suffix(500).filter { $0.averageMaxQ != 0 }),
                xValue: { $0.episode },
                yValue: { $0.averageMaxQ },
                color: .purple,
                averageValue: nil
            )
            
            MetricChart(
                title: "TD Error",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.averageTDError },
                color: .pink,
                averageValue: nil
            )
            
            MetricChart(
                title: "Epsilon",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.epsilon },
                color: .cyan,
                averageValue: nil
            )
        }
    }
}


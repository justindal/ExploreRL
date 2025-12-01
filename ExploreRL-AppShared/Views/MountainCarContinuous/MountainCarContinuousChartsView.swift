//
//  MountainCarContinuousChartsView.swift
//

import SwiftUI

struct MountainCarContinuousChartsView: View {
    var runner: MountainCarContinuousRunner
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
                title: "Alpha (Entropy)",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.epsilon },
                color: .purple,
                averageValue: nil
            )
            
            MetricChart(
                title: "Success Rate",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.success ? 1.0 : 0.0 },
                color: .green,
                averageValue: nil
            )
        }
    }
}


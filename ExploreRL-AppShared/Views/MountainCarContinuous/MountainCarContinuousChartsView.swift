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
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .blue,
                averageValue: nil
            )
            
            MetricChart(
                title: "Steps (Duration)",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { Double($0.steps) },
                color: .orange,
                averageValue: nil
            )
            
            MetricChart(
                title: "Alpha (Entropy)",
                data: runner.episodeMetrics.filter { $0.alpha != nil },
                xValue: { $0.episode },
                yValue: { $0.alpha ?? 0 },
                color: .purple,
                averageValue: nil
            )
            
            MetricChart(
                title: "Success Rate",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.success ? 1.0 : 0.0 },
                color: .green,
                averageValue: nil
            )
        }
    }
}


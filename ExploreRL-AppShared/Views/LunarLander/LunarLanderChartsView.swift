//
//  LunarLanderChartsView.swift
//

import SwiftUI

struct LunarLanderChartsView: View {
    var runner: LunarLanderRunner
    var columns: [GridItem] = []
    
    var body: some View {
        LazyVGrid(columns: columns.isEmpty ? [GridItem(.flexible())] : columns, spacing: 10) {
            MetricChart(
                title: "Episode Rewards",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .green,
                averageValue: runner.averageReward
            )
            
            MetricChart(
                title: "Steps (Duration)",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { Double($0.steps) },
                color: .blue,
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
                title: "Epsilon",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.epsilon ?? 1.0 },
                color: .orange,
                averageValue: nil
            )
            
            MetricChart(
                title: "TD Error",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.averageTDError },
                color: .cyan,
                averageValue: nil
            )
            
            MetricChart(
                title: "Gradient Norm",
                data: Array(runner.episodeMetrics.suffix(500).filter { $0.averageGradNorm != nil }),
                xValue: { $0.episode },
                yValue: { $0.averageGradNorm ?? 0 },
                color: .pink,
                averageValue: nil
            )
        }
    }
}

//
//  CartPoleChartsView.swift
//

import SwiftUI

struct CartPoleChartsView: View {
    var runner: CartPoleRunner
    var columns: [GridItem] = []
    
    var body: some View {
        LazyVGrid(columns: columns.isEmpty ? [GridItem(.flexible())] : columns, spacing: 10) {
            MetricChart(
                title: "Episode Rewards",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .blue,
                averageValue: runner.averageReward
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
                title: "Gradient Norm",
                data: Array(runner.episodeMetrics.suffix(500).filter { $0.averageGradNorm != nil }),
                xValue: { $0.episode },
                yValue: { $0.averageGradNorm ?? 0 },
                color: .cyan,
                averageValue: nil
            )
        }
    }
}

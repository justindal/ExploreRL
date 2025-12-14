//
//  LunarLanderContinuousChartsView.swift
//

import SwiftUI

struct LunarLanderContinuousChartsView: View {
    var runner: LunarLanderContinuousRunner
    var columns: [GridItem] = []
    
    var body: some View {
        LazyVGrid(columns: columns.isEmpty ? [GridItem(.flexible())] : columns, spacing: 10) {
            MetricChart(
                title: "Episode Rewards",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .teal,
                averageValue: runner.averageReward
            )
            
            MetricChart(
                title: "Steps (Duration)",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { Double($0.steps) },
                color: .blue,
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
                title: "Reward Moving Avg",
                data: runner.episodeMetrics.filter { $0.rewardMovingAverage != nil },
                xValue: { $0.episode },
                yValue: { $0.rewardMovingAverage ?? 0 },
                color: .green,
                averageValue: nil
            )
        }
    }
}

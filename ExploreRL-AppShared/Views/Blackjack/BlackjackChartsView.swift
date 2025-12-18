//
//  BlackjackChartsView.swift
//

import SwiftUI

struct BlackjackChartsView: View {
    var runner: BlackjackRunner
    var columns: [GridItem] = []
    
    var body: some View {
        LazyVGrid(columns: columns.isEmpty ? [GridItem(.flexible())] : columns, spacing: 10) {
            MetricChart(
                title: "Win Rate",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.reward > 0 ? 1.0 : 0.0 },
                color: .green,
                averageValue: runner.winRate
            )
            
            MetricChart(
                title: "Episode Rewards",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .blue,
                averageValue: runner.averageReward
            )
            
            MetricChart(
                title: "Steps per Episode",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { Double($0.steps) },
                color: .orange,
                averageValue: runner.averageSteps
            )
            
            MetricChart(
                title: "TD Error",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.averageTDError },
                color: .purple,
                averageValue: nil
            )
            
            MetricChart(
                title: "Max Q-Value",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.averageMaxQ },
                color: .pink,
                averageValue: nil
            )
            
            MetricChart(
                title: "Epsilon",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.epsilon },
                color: .cyan,
                averageValue: nil
            )
        }
    }
}


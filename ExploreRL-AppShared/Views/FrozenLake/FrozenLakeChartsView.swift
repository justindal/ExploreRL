//
//  FrozenLakeChartsView.swift
//

import SwiftUI

struct FrozenLakeChartsView: View {
    var runner: FrozenLakeRunner
    
    var body: some View {
        VStack(spacing: 15) {
            MetricChart(
                title: "Success Rate",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.success ? 1.0 : 0.0 },
                color: .green,
                averageValue: runner.successRate
            )
            
            MetricChart(
                title: "Episode Rewards",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .blue,
                averageValue: runner.averageReward
            )
            
            MetricChart(
                title: "Steps per Episode",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { Double($0.steps) },
                color: .orange,
                averageValue: runner.averageSteps
            )
            
            MetricChart(
                title: "Avg TD Error (Convergence)",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.averageTDError },
                color: .purple,
                averageValue: runner.averageTDError
            )
            
            MetricChart(
                title: "Avg Max Q-Value (Optimism)",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.averageMaxQ },
                color: .pink,
                averageValue: runner.averageMaxQ
            )
            
            MetricChart(
                title: "Epsilon (Exploration Rate)",
                data: Array(runner.episodeMetrics.suffix(500)),
                xValue: { $0.episode },
                yValue: { $0.epsilon },
                color: .gray,
                averageValue: nil
            )
        }
    }
}


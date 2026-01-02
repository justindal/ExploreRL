import SwiftUI

struct CarRacingDiscreteChartsView: View {
    var runner: CarRacingDiscreteRunner
    var columns: [GridItem] = []
    
    var body: some View {
        LazyVGrid(columns: columns.isEmpty ? [GridItem(.flexible())] : columns, spacing: 10) {
            MetricChart(
                title: "Episode Rewards",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.reward },
                color: .gray,
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
                title: "Loss",
                data: runner.episodeMetrics.filter { $0.averageLoss != nil },
                xValue: { $0.episode },
                yValue: { $0.averageLoss ?? 0 },
                color: .red,
                averageValue: nil
            )
            
            MetricChart(
                title: "Max Q-Value",
                data: runner.episodeMetrics.filter { $0.averageMaxQ != 0 },
                xValue: { $0.episode },
                yValue: { $0.averageMaxQ },
                color: .purple,
                averageValue: nil
            )
            
            MetricChart(
                title: "Epsilon",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.epsilon },
                color: .orange,
                averageValue: nil
            )
            
            MetricChart(
                title: "TD Error",
                data: runner.episodeMetrics,
                xValue: { $0.episode },
                yValue: { $0.averageTDError },
                color: .cyan,
                averageValue: nil
            )
            
            MetricChart(
                title: "Gradient Norm",
                data: runner.episodeMetrics.filter { $0.averageGradNorm != nil },
                xValue: { $0.episode },
                yValue: { $0.averageGradNorm ?? 0 },
                color: .pink,
                averageValue: nil
            )
        }
    }
}


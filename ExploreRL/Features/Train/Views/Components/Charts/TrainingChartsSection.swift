//
//  TrainingChartsSection.swift
//  ExploreRL
//

import SwiftUI

enum ChartMetric: String, CaseIterable, Identifiable {
    case reward = "Reward"
    case length = "Length"
    case exploration = "Epsilon"
    case loss = "Loss"
    case tdError = "TD Error"
    case qValue = "Q-Value"
    case learningRate = "LR"

    var id: String { rawValue }
}

struct TrainingChartsSection: View {
    let state: TrainingState
    @State private var selected: ChartMetric = .reward

    private var availableMetrics: [ChartMetric] {
        ChartMetric.allCases.filter { metric in
            switch metric {
            case .reward: !state.rewardHistory.isEmpty
            case .length: !state.episodeLengthHistory.isEmpty
            case .exploration: !state.explorationRateHistory.isEmpty
            case .loss: !state.lossHistory.isEmpty
            case .tdError: !state.tdErrorHistory.isEmpty
            case .qValue: !state.qValueHistory.isEmpty
            case .learningRate: !state.learningRateHistory.isEmpty
            }
        }
    }

    var body: some View {
        if !availableMetrics.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Charts")
                        .font(.headline)
                    Spacer()
                    legendLabel
                }

                metricPicker

                chartContent
                    .frame(height: 200)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .onChange(of: availableMetrics) { _, metrics in
                if !metrics.contains(selected), let first = metrics.first {
                    selected = first
                }
            }
        }
    }

    @ViewBuilder
    private var metricPicker: some View {
        if availableMetrics.count > 1 {
            if availableMetrics.count > 5 {
                Picker("Metric", selection: $selected) {
                    ForEach(availableMetrics) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
            } else {
                Picker("Metric", selection: $selected) {
                    ForEach(availableMetrics) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        switch selected {
        case .reward:
            TrainingChart(data: state.rewardHistory, color: .blue, label: "Reward")
        case .length:
            TrainingChart(data: state.episodeLengthHistory, color: .green, label: "Steps")
        case .exploration:
            TrainingChart(data: state.explorationRateHistory, color: .orange, label: "Epsilon", showAverage: false)
        case .loss:
            TrainingChart(data: state.lossHistory, color: .red, label: "Loss")
        case .tdError:
            TrainingChart(data: state.tdErrorHistory, color: .pink, label: "TD Error")
        case .qValue:
            TrainingChart(data: state.qValueHistory, color: .cyan, label: "Q-Value")
        case .learningRate:
            TrainingChart(data: state.learningRateHistory, color: .purple, label: "LR", showAverage: false)
        }
    }

    private var legendLabel: some View {
        HStack(spacing: 12) {
            if showsAverage {
                HStack(spacing: 4) {
                    Circle()
                        .fill(chartColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Raw")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(chartColor)
                        .frame(width: 8, height: 8)
                    Text("Avg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var showsAverage: Bool {
        switch selected {
        case .exploration, .learningRate: false
        default: true
        }
    }

    private var chartColor: Color {
        switch selected {
        case .reward: .blue
        case .length: .green
        case .exploration: .orange
        case .loss: .red
        case .tdError: .pink
        case .qValue: .cyan
        case .learningRate: .purple
        }
    }
}

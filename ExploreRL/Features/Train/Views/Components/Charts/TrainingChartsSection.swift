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
    case actorLoss = "Actor Loss"
    case criticLoss = "Critic Loss"
    case entropyCoef = "Entropy Coef"
    case tdError = "TD Error"
    case qValue = "Q-Value"
    case learningRate = "LR"

    var id: String { rawValue }
}

struct TrainingChartsSection: View {
    let state: TrainingState
    @State private var selected: ChartMetric = .reward
    @State private var lockYScale = false

    private var availableMetrics: [ChartMetric] {
        ChartMetric.allCases.filter { metric in
            switch metric {
            case .reward: !state.rewardHistory.isEmpty
            case .length: !state.episodeLengthHistory.isEmpty
            case .exploration: !state.explorationRateHistory.isEmpty
            case .loss: hasDistinctLossSeries
            case .actorLoss: !state.actorLossHistory.isEmpty
            case .criticLoss: !state.criticLossHistory.isEmpty
            case .entropyCoef: !state.entropyCoefHistory.isEmpty
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
                chartOptions

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
            .onChange(of: selected) { _, _ in
                lockYScale = false
            }
            .onAppear {
                if !availableMetrics.contains(selected), let first = availableMetrics.first {
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
                .pickerStyle(.menu)
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
            TrainingChart(
                data: points(state.rewardStepHistory, state.rewardHistory),
                color: .blue,
                label: "Reward",
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .length:
            TrainingChart(
                data: points(state.episodeLengthStepHistory, state.episodeLengthHistory),
                color: .green,
                label: "Steps",
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .exploration:
            TrainingChart(
                data: points(state.explorationRateStepHistory, state.explorationRateHistory),
                color: .orange,
                label: "Epsilon",
                showAverage: false,
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .loss:
            TrainingChart(
                data: points(state.lossStepHistory, state.lossHistory),
                color: .red,
                label: "Loss",
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .actorLoss:
            TrainingChart(
                data: points(state.actorLossStepHistory, state.actorLossHistory),
                color: .indigo,
                label: "Actor Loss",
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .criticLoss:
            TrainingChart(
                data: points(state.criticLossStepHistory, state.criticLossHistory),
                color: .pink,
                label: "Critic Loss",
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .entropyCoef:
            TrainingChart(
                data: points(state.entropyCoefStepHistory, state.entropyCoefHistory),
                color: .teal,
                label: "Entropy Coef",
                showAverage: false,
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .tdError:
            TrainingChart(
                data: points(state.tdErrorStepHistory, state.tdErrorHistory),
                color: .pink,
                label: "TD Error",
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .qValue:
            TrainingChart(
                data: points(state.qValueStepHistory, state.qValueHistory),
                color: .cyan,
                label: "Q-Value",
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        case .learningRate:
            TrainingChart(
                data: points(state.learningRateStepHistory, state.learningRateHistory),
                color: .purple,
                label: "LR",
                showAverage: false,
                scaleMode: chartScaleMode,
                lockYScale: lockYScale
            )
        }
    }

    @ViewBuilder
    private var chartOptions: some View {
        HStack {
            Spacer()
            Toggle(isOn: $lockYScale) {
                Text("Lock Y-axis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
        }
    }

    private var legendLabel: some View {
        HStack(spacing: 12) {
            if showsAverage {
                HStack(spacing: 4) {
                    Circle()
                        .fill(chartColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Sample")
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
        case .exploration, .entropyCoef, .learningRate: false
        default: true
        }
    }

    private var chartColor: Color {
        switch selected {
        case .reward: .blue
        case .length: .green
        case .exploration: .orange
        case .loss: .red
        case .actorLoss: .indigo
        case .criticLoss: .pink
        case .entropyCoef: .teal
        case .tdError: .pink
        case .qValue: .cyan
        case .learningRate: .purple
        }
    }

    private var chartScaleMode: TrainingChartScaleMode {
        switch selected {
        case .exploration:
            .fixed(0...1)
        case .loss, .actorLoss, .criticLoss, .tdError, .qValue:
            .percentile(lower: 0.02, upper: 0.98)
        default:
            .automatic
        }
    }

    private func points(_ steps: [Int], _ values: [Double]) -> [TrainingChartPoint] {
        let count = min(steps.count, values.count)
        guard count > 0 else { return [] }
        var result: [TrainingChartPoint] = []
        result.reserveCapacity(count)
        var lastStep = Int.min
        var isSorted = true
        for index in 0..<count {
            let point = TrainingChartPoint(step: steps[index], value: values[index])
            if point.step < lastStep {
                isSorted = false
            }
            lastStep = point.step
            result.append(point)
        }
        if isSorted {
            return result
        }
        return result.sorted { lhs, rhs in
            if lhs.step == rhs.step {
                return lhs.value < rhs.value
            }
            return lhs.step < rhs.step
        }
    }

    private var hasDistinctLossSeries: Bool {
        if state.lossHistory.isEmpty {
            return false
        }
        if state.criticLossHistory.isEmpty {
            return true
        }
        guard state.lossHistory.count == state.criticLossHistory.count,
            state.lossStepHistory.count == state.criticLossStepHistory.count
        else {
            return true
        }
        let stepsMatch = zip(state.lossStepHistory, state.criticLossStepHistory).allSatisfy {
            $0 == $1
        }
        if !stepsMatch {
            return true
        }
        let valuesMatch = zip(state.lossHistory, state.criticLossHistory).allSatisfy {
            let scale = max(1.0, max(abs($0), abs($1)))
            return abs($0 - $1) <= (1e-6 * scale)
        }
        return !valuesMatch
    }
}

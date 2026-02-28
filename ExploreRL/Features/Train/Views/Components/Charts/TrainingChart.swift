//
//  TrainingChart.swift
//  ExploreRL
//

import Charts
import SwiftUI

struct TrainingChartPoint: Equatable {
    let step: Int
    let value: Double
}

enum TrainingChartScaleMode {
    case automatic
    case percentile(lower: Double, upper: Double)
}

struct TrainingChart: View {
    let data: [TrainingChartPoint]
    let color: Color
    let label: String
    var showAverage: Bool = true
    var averageWindow: Int = 100
    var scaleMode: TrainingChartScaleMode = .automatic

    private static let maxDisplayPoints = 500

    var body: some View {
        if data.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.line.downtrend.xyaxis"
            )
        } else {
            chart
        }
    }

    @ViewBuilder
    private var chart: some View {
        let display = sampled
        let avg = showAverage ? rollingAverage(of: display) : []
        let baseChart = Chart {
            ForEach(Array(display.enumerated()), id: \.offset) { i, v in
                LineMark(
                    x: .value("Step", v.step),
                    y: .value(label, v.value),
                    series: .value("Series", "Raw")
                )
            }
            .foregroundStyle(color.opacity(0.2))

            if !avg.isEmpty {
                ForEach(Array(avg.enumerated()), id: \.offset) { i, v in
                    LineMark(
                        x: .value("Step", v.step),
                        y: .value(label, v.value),
                        series: .value("Series", "Average")
                    )
                }
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartLegend(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.clipped()
        }
        .chartXAxis {
            AxisMarks(preset: .automatic)
        }
        .chartYAxis {
            AxisMarks(preset: .automatic)
        }

        if let yDomain = yDomain {
            baseChart
                .chartYScale(domain: yDomain)
        } else {
            baseChart
        }
    }

    private var sampled: [TrainingChartPoint] {
        let targetCount = Self.maxDisplayPoints
        guard data.count > targetCount else { return data }
        let stride = Double(data.count - 1) / Double(targetCount - 1)
        var result: [TrainingChartPoint] = []
        result.reserveCapacity(targetCount)
        var lastIndex = -1
        for i in 0..<targetCount {
            let index = Int((Double(i) * stride).rounded())
            if index != lastIndex {
                result.append(data[index])
                lastIndex = index
            }
        }
        if let last = data.last, result.last != last {
            result.append(last)
        }
        return result
    }

    private func rollingAverage(of values: [TrainingChartPoint]) -> [TrainingChartPoint] {
        guard values.count > 1 else { return [] }
        let window = min(averageWindow, values.count / 2)
        guard window > 1 else { return [] }
        var result: [TrainingChartPoint] = []
        result.reserveCapacity(values.count)
        var windowSum = 0.0
        for i in values.indices {
            windowSum += values[i].value
            if i >= window {
                windowSum -= values[i - window].value
            }
            let size = Double(min(i + 1, window))
            result.append(
                TrainingChartPoint(
                    step: values[i].step,
                    value: windowSum / size
                )
            )
        }
        return result
    }

    private var yDomain: ClosedRange<Double>? {
        switch scaleMode {
        case .automatic:
            return nil
        case .percentile(let lower, let upper):
            let values = data.map(\.value)
            guard values.count >= 5 else { return nil }
            let sorted = values.sorted()
            let low = percentile(sorted, p: lower)
            let high = percentile(sorted, p: upper)
            guard low.isFinite, high.isFinite else { return nil }
            if low == high {
                let delta = max(1e-6, abs(low) * 0.05)
                return (low - delta)...(high + delta)
            }
            let padding = (high - low) * 0.05
            return (low - padding)...(high + padding)
        }
    }

    private func percentile(_ sorted: [Double], p: Double) -> Double {
        guard !sorted.isEmpty else { return 0.0 }
        let clamped = min(max(p, 0.0), 1.0)
        let position = clamped * Double(sorted.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = Int(position.rounded(.up))
        if lower == upper {
            return sorted[lower]
        }
        let weight = position - Double(lower)
        return sorted[lower] + (sorted[upper] - sorted[lower]) * weight
    }
}

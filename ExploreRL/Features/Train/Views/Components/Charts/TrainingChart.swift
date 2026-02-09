//
//  TrainingChart.swift
//  ExploreRL
//

import Charts
import SwiftUI

struct TrainingChart: View {
    let data: [Double]
    let color: Color
    let label: String
    var showAverage: Bool = true
    var averageWindow: Int = 100

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

    private var chart: some View {
        let display = downsampled
        let avg = showAverage ? rollingAverage(of: display) : []

        return Chart {
            ForEach(Array(display.enumerated()), id: \.offset) { i, v in
                LineMark(
                    x: .value("Index", i),
                    y: .value(label, v),
                    series: .value("Series", "Raw")
                )
            }
            .foregroundStyle(color.opacity(0.2))

            if !avg.isEmpty {
                ForEach(Array(avg.enumerated()), id: \.offset) { i, v in
                    LineMark(
                        x: .value("Index", i),
                        y: .value(label, v),
                        series: .value("Series", "Average")
                    )
                }
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(preset: .automatic)
        }
        .chartYAxis {
            AxisMarks(preset: .automatic)
        }
    }

    private var downsampled: [Double] {
        let max = Self.maxDisplayPoints
        guard data.count > max else { return data }
        let stride = Double(data.count) / Double(max)
        return (0..<max).map { i in
            let start = Int(Double(i) * stride)
            let end = min(Int(Double(i + 1) * stride), data.count)
            let slice = data[start..<end]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }

    private func rollingAverage(of values: [Double]) -> [Double] {
        guard values.count > 1 else { return [] }
        let window = min(averageWindow, values.count / 2)
        guard window > 1 else { return [] }
        var result: [Double] = []
        result.reserveCapacity(values.count)
        var windowSum = 0.0
        for i in values.indices {
            windowSum += values[i]
            if i >= window {
                windowSum -= values[i - window]
            }
            let size = Double(min(i + 1, window))
            result.append(windowSum / size)
        }
        return result
    }
}

//
//  MetricChart.swift
//

import SwiftUI
import Charts

struct MetricChart<DataPoint: Identifiable>: View {
    let title: String
    let data: [DataPoint]
    let xValue: (DataPoint) -> Int
    let yValue: (DataPoint) -> Double
    let color: Color
    let averageValue: Double?
    
    let maxPlotPoints: Int
    
    init(
        title: String,
        data: [DataPoint],
        xValue: @escaping (DataPoint) -> Int,
        yValue: @escaping (DataPoint) -> Double,
        color: Color,
        averageValue: Double? = nil,
        maxPlotPoints: Int = 900
    ) {
        self.title = title
        self.data = data
        self.xValue = xValue
        self.yValue = yValue
        self.color = color
        self.averageValue = averageValue
        self.maxPlotPoints = maxPlotPoints
    }
    
    private var currentValue: Double? {
        guard let last = data.last else { return nil }
        return yValue(last)
    }
    
    private var sortedSeries: [(x: Int, y: Double)] {
        data
            .map { (x: xValue($0), y: yValue($0)) }
            .sorted { $0.x < $1.x }
    }
    
    private var downsampledSeries: [(x: Int, y: Double)] {
        downsample(series: sortedSeries, maxPoints: maxPlotPoints)
    }
    
    private var downsampledRunningAverageSeries: [(x: Int, y: Double)] {
        let raw = sortedSeries
        guard !raw.isEmpty else { return [] }
        
        var running: [(x: Int, y: Double)] = []
        running.reserveCapacity(raw.count)
        
        var sum = 0.0
        for (i, p) in raw.enumerated() {
            sum += p.y
            let avg = sum / Double(i + 1)
            running.append((x: p.x, y: avg))
        }
        
        return downsample(series: running, maxPoints: maxPlotPoints)
    }
    
    private var contrastingAverageColor: Color {
        switch color {
        case .blue:
            return .orange
        case .green:
            return .pink
        case .orange:
            return .blue
        case .red:
            return .cyan
        case .purple:
            return .yellow
        case .pink:
            return .teal
        case .cyan:
            return .red
        case .yellow:
            return .purple
        case .teal:
            return .pink
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            chartView
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Spacer()
            if let current = currentValue {
                Text(formatValue(current))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
        }
    }
    
    private var chartView: some View {
        Chart {
            chartContent
        }
        .chartForegroundStyleScale([
            "Value": color,
            "Avg": contrastingAverageColor
        ])
        .chartLegend(position: .top, alignment: .leading)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 100)
    }
    
    @ChartContentBuilder
    private var chartContent: some ChartContent {
        ForEach(downsampledSeries, id: \.x) { p in
            LineMark(
                x: .value("Episode", p.x),
                y: .value("Value", p.y)
            )
            .foregroundStyle(by: .value("Series", "Value"))
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.linear)
        }
        
        ForEach(downsampledRunningAverageSeries, id: \.x) { p in
            LineMark(
                x: .value("Episode", p.x),
                y: .value("Average", p.y)
            )
            .foregroundStyle(by: .value("Series", "Avg"))
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 4]))
            .interpolationMethod(.linear)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if Swift.abs(value) >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else if Swift.abs(value) >= 100 {
            return String(format: "%.0f", value)
        } else if Swift.abs(value) >= 10 {
            return String(format: "%.1f", value)
        } else if Swift.abs(value) >= 1 {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.3f", value)
        }
    }
    
    private func downsample(series: [(x: Int, y: Double)], maxPoints: Int) -> [(x: Int, y: Double)] {
        guard maxPoints > 2 else { return series.prefix(2).map { $0 } }
        guard series.count > maxPoints else { return series }
        
        let n = series.count
        let target = maxPoints
        let stride = Double(n - 1) / Double(target - 1)
        
        var sampled: [(x: Int, y: Double)] = []
        sampled.reserveCapacity(target)
        
        var lastIndex = -1
        for i in 0..<target {
            let idx = Int((Double(i) * stride).rounded(.down))
            if idx != lastIndex {
                sampled.append(series[idx])
                lastIndex = idx
            }
        }
        
        if sampled.last?.x != series.last?.x {
            sampled.append(series.last!)
        }
        
        return sampled
    }
}


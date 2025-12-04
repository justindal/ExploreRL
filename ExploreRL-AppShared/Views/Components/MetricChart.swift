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
    
    private var currentValue: Double? {
        guard let last = data.last else { return nil }
        return yValue(last)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            Chart {
                ForEach(data) { point in
                    PointMark(
                        x: .value("X", xValue(point)),
                        y: .value("Y", yValue(point))
                    )
                    .symbolSize(15)
                    .foregroundStyle(color.opacity(0.25))
                }
                
                if data.count > 1 {
                    let trendData = calculateMovingAverage(data: data, windowSize: min(20, max(3, data.count / 5)))
                    ForEach(trendData.indices, id: \.self) { index in
                        let point = trendData[index]
                        LineMark(
                            x: .value("X", point.x),
                            y: .value("Trend", point.y)
                        )
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
                
                if let avg = averageValue {
                    RuleMark(y: .value("Average", avg))
                        .foregroundStyle(color.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 100)
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
    
    private func calculateMovingAverage(data: [DataPoint], windowSize: Int) -> [(x: Int, y: Double)] {
        var result: [(x: Int, y: Double)] = []
        for i in 0..<data.count {
            let start = max(0, i - windowSize + 1)
            let window = data[start...i]
            let sum = window.reduce(0.0) { $0 + yValue($1) }
            let avg = sum / Double(window.count)
            result.append((x: xValue(data[i]), y: avg))
        }
        return result
    }
}


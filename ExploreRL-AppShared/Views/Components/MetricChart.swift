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
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let avg = averageValue {
                    Text("Avg: \(String(format: "%.2f", avg))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Chart {
                ForEach(data) { point in
                    PointMark(
                        x: .value("X", xValue(point)),
                        y: .value("Y", yValue(point))
                    )
                    .foregroundStyle(color.opacity(0.3))
                }
                
                if let avg = averageValue {
                    RuleMark(y: .value("Average", avg))
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}


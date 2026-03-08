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

enum TrainingChartScaleMode: Equatable {
    case automatic
    case fixed(ClosedRange<Double>)
    case percentile(lower: Double, upper: Double)
}

struct TrainingChart: View {
    let data: [TrainingChartPoint]
    let color: Color
    let label: String
    var showAverage: Bool = true
    var averageWindow: Int = 100
    var scaleMode: TrainingChartScaleMode = .automatic
    var lockYScale: Bool = false

    private static let maxDisplayPoints = 500

    @State private var prepared: PreparedData
    @State private var selectedStep: Int?
    @State private var lockedYDomain: ClosedRange<Double>?

    init(
        data: [TrainingChartPoint],
        color: Color,
        label: String,
        showAverage: Bool = true,
        averageWindow: Int = 100,
        scaleMode: TrainingChartScaleMode = .automatic,
        lockYScale: Bool = false
    ) {
        self.data = data
        self.color = color
        self.label = label
        self.showAverage = showAverage
        self.averageWindow = averageWindow
        self.scaleMode = scaleMode
        self.lockYScale = lockYScale
        _prepared = State(
            initialValue: Self.prepare(
                data: data,
                showAverage: showAverage,
                averageWindow: averageWindow,
                scaleMode: scaleMode
            )
        )
    }

    var body: some View {
        if prepared.display.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.line.downtrend.xyaxis"
            )
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if let point = selectedPoint {
                    HStack(spacing: 8) {
                        Text("Step \(point.step.formatted())")
                        Spacer()
                        Text(point.value.formatted(.number.precision(.fractionLength(4))))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
                chart
            }
            .onAppear {
                syncLockedDomain()
            }
            .onChange(of: refreshKey) { _, _ in
                recomputePrepared()
            }
            .onChange(of: lockYScale) { _, _ in
                syncLockedDomain()
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        let baseChart = Chart {
            ForEach(Array(prepared.display.enumerated()), id: \.offset) { _, v in
                LineMark(
                    x: .value("Step", v.step),
                    y: .value(label, v.value),
                    series: .value("Series", "Raw")
                )
            }
            .foregroundStyle(color.opacity(0.2))

            if !prepared.average.isEmpty {
                ForEach(Array(prepared.average.enumerated()), id: \.offset) { _, v in
                    LineMark(
                        x: .value("Step", v.step),
                        y: .value(label, v.value),
                        series: .value("Series", "Average")
                    )
                }
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            if let point = selectedPoint {
                RuleMark(
                    x: .value("Step", point.step)
                )
                .foregroundStyle(.secondary.opacity(0.35))

                PointMark(
                    x: .value("Step", point.step),
                    y: .value(label, point.value)
                )
                .foregroundStyle(color)
                .symbolSize(32)
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else {
                                    selectedStep = nil
                                    return
                                }
                                let frame = geometry[plotFrame]
                                let x = value.location.x - frame.origin.x
                                guard x >= 0, x <= frame.width else {
                                    selectedStep = nil
                                    return
                                }
                                if let step: Int = proxy.value(atX: x) {
                                    selectedStep = step
                                }
                            }
                            .onEnded { _ in
                                selectedStep = nil
                            }
                    )
            }
        }

        if let yDomain = activeYDomain {
            baseChart
                .chartYScale(domain: yDomain)
        } else {
            baseChart
        }
    }

    private var activeYDomain: ClosedRange<Double>? {
        if lockYScale {
            return lockedYDomain
                ?? prepared.yDomain
                ?? Self.automaticDomain(for: prepared.display)
        }
        return prepared.yDomain
    }

    private var selectedPoint: TrainingChartPoint? {
        guard let selectedStep else { return nil }
        return nearestPoint(to: selectedStep, in: prepared.display)
    }

    private var refreshKey: RefreshKey {
        RefreshKey(
            count: data.count,
            firstStep: data.first?.step ?? -1,
            lastStep: data.last?.step ?? -1,
            lastValue: data.last?.value ?? 0,
            showAverage: showAverage,
            averageWindow: averageWindow,
            scaleMode: scaleMode
        )
    }

    private func recomputePrepared() {
        prepared = Self.prepare(
            data: data,
            showAverage: showAverage,
            averageWindow: averageWindow,
            scaleMode: scaleMode
        )
        syncLockedDomain()
    }

    private func syncLockedDomain() {
        if lockYScale {
            if lockedYDomain == nil {
                lockedYDomain = prepared.yDomain
                    ?? Self.automaticDomain(for: prepared.display)
            }
        } else {
            lockedYDomain = nil
        }
    }

    private func nearestPoint(
        to step: Int,
        in values: [TrainingChartPoint]
    ) -> TrainingChartPoint? {
        guard !values.isEmpty else { return nil }
        var low = 0
        var high = values.count - 1
        while low < high {
            let mid = (low + high) / 2
            if values[mid].step < step {
                low = mid + 1
            } else {
                high = mid
            }
        }
        let candidate = values[low]
        if low == 0 {
            return candidate
        }
        let previous = values[low - 1]
        return abs(previous.step - step) <= abs(candidate.step - step)
            ? previous : candidate
    }

    private static func prepare(
        data: [TrainingChartPoint],
        showAverage: Bool,
        averageWindow: Int,
        scaleMode: TrainingChartScaleMode
    ) -> PreparedData {
        let display = sampled(from: data)
        let average = showAverage
            ? rollingAverage(of: display, averageWindow: averageWindow)
            : []
        let yDomain = domain(for: display, scaleMode: scaleMode)
        return PreparedData(display: display, average: average, yDomain: yDomain)
    }

    private static func sampled(from values: [TrainingChartPoint]) -> [TrainingChartPoint] {
        let maxPoints = Self.maxDisplayPoints
        guard values.count > maxPoints, values.count > 2 else { return values }

        let bucketCount = max(1, (maxPoints - 2) / 2)
        let inner = Array(values.dropFirst().dropLast())
        guard !inner.isEmpty else { return values }

        var result: [TrainingChartPoint] = []
        result.reserveCapacity(maxPoints)
        if let first = values.first {
            result.append(first)
        }

        let bucketSize = Double(inner.count) / Double(bucketCount)
        for bucket in 0..<bucketCount {
            let start = Int((Double(bucket) * bucketSize).rounded(.down))
            var end = Int((Double(bucket + 1) * bucketSize).rounded(.down))
            if bucket == bucketCount - 1 {
                end = inner.count
            }
            guard start < end else { continue }

            var minPoint = inner[start]
            var maxPoint = inner[start]
            for index in start..<end {
                let point = inner[index]
                if point.value < minPoint.value {
                    minPoint = point
                }
                if point.value > maxPoint.value {
                    maxPoint = point
                }
            }

            if minPoint == maxPoint {
                if result.last != minPoint {
                    result.append(minPoint)
                }
            } else if minPoint.step <= maxPoint.step {
                if result.last != minPoint {
                    result.append(minPoint)
                }
                if result.last != maxPoint {
                    result.append(maxPoint)
                }
            } else {
                if result.last != maxPoint {
                    result.append(maxPoint)
                }
                if result.last != minPoint {
                    result.append(minPoint)
                }
            }
        }

        if let last = values.last, result.last != last {
            result.append(last)
        }
        return result
    }

    private static func rollingAverage(
        of values: [TrainingChartPoint],
        averageWindow: Int
    ) -> [TrainingChartPoint] {
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

    private static func domain(
        for values: [TrainingChartPoint],
        scaleMode: TrainingChartScaleMode
    ) -> ClosedRange<Double>? {
        switch scaleMode {
        case .automatic:
            return nil
        case .fixed(let domain):
            return domain
        case .percentile(let lower, let upper):
            let scalarValues = values.map(\.value)
            guard scalarValues.count >= 5 else { return nil }
            let sorted = scalarValues.sorted()
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

    private static func automaticDomain(
        for values: [TrainingChartPoint]
    ) -> ClosedRange<Double>? {
        guard let minValue = values.map(\.value).min(),
              let maxValue = values.map(\.value).max()
        else {
            return nil
        }
        if minValue == maxValue {
            let delta = max(1e-6, abs(minValue) * 0.05)
            return (minValue - delta)...(maxValue + delta)
        }
        let padding = (maxValue - minValue) * 0.05
        return (minValue - padding)...(maxValue + padding)
    }

    private static func percentile(_ sorted: [Double], p: Double) -> Double {
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

    private struct PreparedData {
        let display: [TrainingChartPoint]
        let average: [TrainingChartPoint]
        let yDomain: ClosedRange<Double>?
    }

    private struct RefreshKey: Equatable {
        let count: Int
        let firstStep: Int
        let lastStep: Int
        let lastValue: Double
        let showAverage: Bool
        let averageWindow: Int
        let scaleMode: TrainingChartScaleMode
    }
}

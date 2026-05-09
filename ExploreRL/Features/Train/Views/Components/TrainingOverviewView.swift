//
//  TrainingOverviewView.swift
//  ExploreRL
//

import SwiftUI

struct TrainingOverviewView: View {
    let trainingState: TrainingState
    let trainingConfig: TrainingConfig
    let elapsed: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            statsGrid
            progressSection
            Divider().opacity(0.4)
            timingRow
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Training Overview")
                    .font(.headline)
                statusLabel
            }
            Spacer()
            AlgorithmBadge(text: trainingConfig.algorithm.rawValue)
        }
    }

    private var statusLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            MetricCard(
                title: "Episodes",
                value: trainingState.episodeCount.formatted()
            )
            MetricCard(
                title: "Steps",
                value: stepsText
            )
        }
    }

    private var progressSection: some View {
        let progress = trainingState.progress(
            totalTimesteps: trainingConfig.totalTimesteps
        )
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", progress * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
        }
    }

    private var timingRow: some View {
        let stepsPerMinute = stepsPerMin(elapsed: elapsed)
        let eta = etaSeconds(stepsPerMinute: stepsPerMinute)
        return HStack(spacing: 0) {
            timingCell(
                label: "Elapsed",
                value: formatTime(elapsed)
            )
            timingDivider
            timingCell(
                label: "Throughput",
                value: throughputText(stepsPerMinute)
            )
            timingDivider
            timingCell(
                label: "ETA",
                value: eta.map(formatTime) ?? "—"
            )
        }
    }

    private var timingDivider: some View {
        Rectangle()
            .fill(.separator)
            .frame(width: 1, height: 28)
    }

    private func timingCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepsText: String {
        "\(trainingState.currentTimestep.formatted()) / \(trainingConfig.totalTimesteps.formatted())"
    }

    private func throughputText(_ stepsPerMinute: Double) -> String {
        guard stepsPerMinute > 0 else { return "—" }
        return "\(Int(stepsPerMinute.rounded()).formatted()) /min"
    }

    private var statusText: String {
        switch trainingState.status {
        case .idle: "Idle"
        case .training: "Training"
        case .paused: "Paused"
        case .completed: "Completed"
        case .failed: "Failed"
        }
    }

    private var statusColor: Color {
        switch trainingState.status {
        case .idle: .secondary
        case .training: .blue
        case .paused: .orange
        case .completed: .green
        case .failed: .red
        }
    }

    private func stepsPerMin(elapsed: TimeInterval) -> Double {
        guard elapsed > 0 else { return 0 }
        return Double(trainingState.currentTimestep) / (elapsed / 60.0)
    }

    private func etaSeconds(stepsPerMinute: Double) -> TimeInterval? {
        guard stepsPerMinute > 0 else { return nil }
        let remaining = max(
            0,
            trainingConfig.totalTimesteps - trainingState.currentTimestep
        )
        return (Double(remaining) / stepsPerMinute) * 60.0
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

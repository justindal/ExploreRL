//
//  TrainingOverviewView.swift
//  ExploreRL
//

import SwiftUI

struct TrainingOverviewView: View {
    let trainingState: TrainingState
    let trainingConfig: TrainingConfig
    let elapsed: TimeInterval
    var timedSteps: Int? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            header
            statsGrid
            progressSection
            Divider().opacity(0.4)
            timingRow
        }
        .padding(AppLayout.panelPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
        )
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
        let stepsPerMinute = stepsPerMin(timesteps: timedSteps ?? trainingState.currentTimestep, elapsed: elapsed)
        let eta = etaSeconds(
            stepsPerMinute: stepsPerMinute, currentTimestep: trainingState.currentTimestep,
            totalTimesteps: trainingConfig.totalTimesteps)
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            timingCell(
                label: "Elapsed",
                value: formatTime(elapsed)
            )
            if !dynamicTypeSize.isAccessibilitySize { timingDivider }
            timingCell(
                label: "Throughput",
                value: throughputText(stepsPerMinute)
            )
            if !dynamicTypeSize.isAccessibilitySize { timingDivider }
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
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .bold()
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

}

//
//  TrainingControlsView.swift
//  ExploreRL
//

import Gymnazo
import SwiftUI

struct TrainingControlsView: View {
    let id: String
    @Bindable var vm: TrainViewModel
    let trainingConfig: TrainingConfig
    let trainingState: TrainingState
    @Binding var showResetAlert: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            trainingContent
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var trainingContent: some View {
        HStack {
            Text("Training")
                .font(.headline)
            Spacer()
            AlgorithmBadge(text: trainingConfig.algorithm.rawValue)
        }

        if trainingState.status != .idle {
            progressBar
        }

        actionBar

        if case .failed(let error) = trainingState.status {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }

        if let reason = policy.reason {
            Text(reason)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        switch trainingState.status {
        case .training:
            actionRow(primary: pauseButton, secondary: resetButton)
        case .paused:
            actionRow(primary: resumeButton, secondary: resetButton)
        case .idle, .completed, .failed:
            idleActionRow
        }
    }

    private var idleActionRow: some View {
        actionRow(primary: startButton, secondary: resetButton)
    }

    private func actionRow(primary: some View, secondary: some View)
        -> some View
    {
        HStack(spacing: 12) {
            primary
                .frame(maxWidth: .infinity)
            secondary
                .frame(maxWidth: .infinity)
        }
        .modify { content in
            if #available(iOS 26.0, macOS 26.0, *) {
                GlassEffectContainer(spacing: 14) {
                    content
                }
            } else {
                content
            }
        }
    }

    private var progress: Double {
        trainingState.progress(totalTimesteps: trainingConfig.totalTimesteps)
    }

    @ViewBuilder
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(trainingState.episodeCount) episodes")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            HStack {
                Text("\(trainingState.currentTimestep) / \(trainingConfig.totalTimesteps) steps")
                    .font(.caption)
                    .monospacedDigit()
                Spacer()
                Text(String(format: "%.1f%%", progress * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
            timingRow
        }
    }

    private var timingRow: some View {
        let elapsed = vm.activeTrainingElapsed(for: id)
        let stepsPerMinute = stepsPerMin(elapsed: elapsed)
        let eta = etaSeconds(stepsPerMinute: stepsPerMinute)

        return HStack {
            Text("Elapsed \(formatTime(elapsed))")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Spacer()
            Text("\(Int(stepsPerMinute.rounded())) steps/min")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Spacer()
            Text(eta.map { "ETA \(formatTime($0))" } ?? "ETA —")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.caption)
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

    private var startButton: some View {
        Button {
            vm.startTraining(for: id)
        } label: {
            Label("Start", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .disabled(!policy.isAllowed)
        .modify { button in
            if #available(iOS 26.0, macOS 26.0, *) {
                button
                    .buttonStyle(.glass(.regular.tint(.blue).interactive()))
                    .controlSize(.large)
                    #if os(macOS)
                    .tint(.blue)
                    #endif
            } else {
                button
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var resumeButton: some View {
        Button {
            vm.startTraining(for: id)
        } label: {
            Label("Resume", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .disabled(!policy.isAllowed)
        .modify { button in
            if #available(iOS 26.0, macOS 26.0, *) {
                button
                    .buttonStyle(.glass(.regular.tint(.green).interactive()))
                    .controlSize(.large)
                    #if os(macOS)
                    .tint(.green)
                    #endif
            } else {
                button
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
    }

    private var pauseButton: some View {
        Button {
            vm.pauseTraining(for: id)
        } label: {
            Label("Pause", systemImage: "pause.fill")
                .frame(maxWidth: .infinity)
        }
        .modify { button in
            if #available(iOS 26.0, macOS 26.0, *) {
                button
                    .buttonStyle(.glass(.regular.tint(.orange).interactive()))
                    .controlSize(.large)
                    #if os(macOS)
                    .tint(.orange)
                    #endif
            } else {
                button
                    .buttonStyle(.bordered)
            }
        }
    }

    private var resetButton: some View {
        Button {
            guard !isResetting else { return }
            if hasTrainingProgress {
                showResetAlert = true
            } else {
                Task { await vm.resetTraining(for: id) }
            }
        } label: {
            Label(
                isResetting ? "Resetting..." : "Reset",
                systemImage: isResetting
                    ? "arrow.triangle.2.circlepath"
                    : "arrow.counterclockwise"
            )
            .frame(maxWidth: .infinity)
        }
        .disabled(isResetting)
        .modify { button in
            let isTraining = trainingState.status == .training
            if #available(iOS 26.0, macOS 26.0, *) {
                button
                    .buttonStyle(
                        isTraining
                            ? .glass(.regular.tint(.red).interactive())
                            : .glass(.clear)
                    )
                    .controlSize(.large)
                    #if os(macOS)
                    .tint(isTraining ? .red : .primary)
                    #endif
            } else {
                button
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(isTraining ? .red : .primary)
            }
        }
    }

    private var policy: TrainingPolicy {
        vm.trainingPolicy(for: id)
    }

    private var hasTrainingProgress: Bool {
        trainingState.currentTimestep > 0 || trainingState.episodeCount > 0
    }

    private var isResetting: Bool {
        vm.isResetting(id: id)
    }
}

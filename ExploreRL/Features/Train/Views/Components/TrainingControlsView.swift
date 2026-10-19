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
    var showDetailedProgress: Bool = true
    var compact = false
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? AppLayout.compactSpacing : 12) {
            trainingContent
        }
        .padding(compact ? 0 : AppLayout.panelPadding)
        .background(
            usesPanelBackground
                ? AnyShapeStyle(.regularMaterial)
                : AnyShapeStyle(.clear),
            in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
        )
    }

    @ViewBuilder
    private var trainingContent: some View {
        if !compact {
            HStack {
                Text("Training")
                    .font(.headline)
                Spacer()
                AlgorithmBadge(text: trainingConfig.algorithm.rawValue)
            }
        }

        if trainingState.status != .idle && showDetailedProgress {
            progressBar
        }

        actionBar

        if !compact, case .failed(let error) = trainingState.status {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }

        if !compact, let message = trainingState.statusMessage {
            Text(message)
                .font(.caption)
                .foregroundStyle(.orange)
        }

        if !compact, trainingState.status != .training, let reason = policy.reason {
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
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: AppLayout.controlRadius))
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
        let stepsPerMinute = stepsPerMin(timesteps: trainingState.currentTimestep, elapsed: elapsed)
        let eta = etaSeconds(
            stepsPerMinute: stepsPerMinute, currentTimestep: trainingState.currentTimestep,
            totalTimesteps: trainingConfig.totalTimesteps)

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

    private var startButton: some View {
        Button {
            vm.startTraining(for: id)
        } label: {
            Label("Start", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .disabled(!policy.isAllowed)
        .keyboardShortcut(.return, modifiers: .command)
        .help("Start training (Command-Return)")
        .buttonStyle(.borderedProminent)
    }

    private var resumeButton: some View {
        Button {
            vm.startTraining(for: id)
        } label: {
            Label("Resume", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .disabled(!policy.isAllowed)
        .keyboardShortcut(.return, modifiers: .command)
        .help("Resume training (Command-Return)")
        .buttonStyle(.borderedProminent)
    }

    private var pauseButton: some View {
        Button {
            Task { await vm.pauseTraining(for: id) }
        } label: {
            Label("Pause", systemImage: "pause.fill")
                .frame(maxWidth: .infinity)
        }
        .keyboardShortcut(.return, modifiers: .command)
        .help("Pause training (Command-Return)")
        .buttonStyle(.borderedProminent)
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
        .keyboardShortcut("r", modifiers: [.command, .shift])
        .help("Reset training (Shift-Command-R)")
        .buttonStyle(.bordered)
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

    private var usesPanelBackground: Bool {
        #if os(iOS)
            !compact && horizontalSizeClass != .compact
        #else
            true
        #endif
    }
}

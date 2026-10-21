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
    @State private var showsContinuation = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? AppLayout.compactSpacing : 12) {
            trainingContent
        }
        .sheet(isPresented: $showsContinuation) {
            ContinueTrainingSheet(id: id, vm: vm)
                .presentationDetents([.medium])
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
            if compact && dynamicTypeSize.isAccessibilitySize {
                ProgressView(value: trainingState.progress(totalTimesteps: trainingConfig.totalTimesteps))
            } else {
                TrainingProgressView(
                    id: id, vm: vm, trainingConfig: trainingConfig, trainingState: trainingState
                )
            }
        }

        actionBar

        if case .failed(let error) = trainingState.status {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }

        if let message = trainingState.statusMessage {
            Text(message)
                .font(.caption)
                .foregroundStyle(.orange)
        }

        if trainingState.status != .training, let reason = policy.reason {
            Text(reason)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        if needsExtension {
            actionRow(primary: continueButton, secondary: resetButton)
        } else {
            switch trainingState.status {
            case .training:
                actionRow(primary: pauseButton, secondary: resetButton)
            case .paused:
                actionRow(primary: resumeButton, secondary: resetButton)
            case .idle, .completed, .failed:
                idleActionRow
            }
        }
    }

    private var needsExtension: Bool {
        trainingState.status != .training && trainingState.currentTimestep > 0
            && trainingState.currentTimestep >= trainingConfig.totalTimesteps
    }

    private var continueButton: some View {
        Button { showsContinuation = true } label: {
            Label("Continue", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
            .disabled(!policy.isAllowed || !vm.canSnapshot(id))
            .modify { button in
                if #available(iOS 26.0, macOS 26.0, *) {
                    button.buttonStyle(.glass(.regular.tint(.green).interactive()))
                        #if os(macOS)
                        .tint(.green)
                        #endif
                } else {
                    button.buttonStyle(.borderedProminent).tint(.green)
                }
            }
    }

    private var idleActionRow: some View {
        actionRow(primary: startButton, secondary: resetButton)
    }

    private func actionRow(primary: some View, secondary: some View)
        -> some View
    {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            primary
                .frame(maxWidth: .infinity)
            secondary
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .modify { content in
            if #available(iOS 26.0, macOS 26.0, *) {
                GlassEffectContainer(spacing: 14) { content }
            } else {
                content
            }
        }
    }

    private var startButton: some View {
        Button {
            vm.startTraining(for: id)
        } label: {
            Label(trainingState.currentTimestep > 0 ? "Resume" : "Start", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .disabled(!policy.isAllowed)
        .keyboardShortcut(.return, modifiers: .command)
        .help("Start training (Command-Return)")
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
        .keyboardShortcut(.return, modifiers: .command)
        .help("Resume training (Command-Return)")
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
            Task { await vm.pauseTraining(for: id) }
        } label: {
            Label("Pause", systemImage: "pause.fill")
                .frame(maxWidth: .infinity)
        }
        .keyboardShortcut(.return, modifiers: .command)
        .help("Pause training (Command-Return)")
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
        .keyboardShortcut("r", modifiers: [.command, .shift])
        .help("Reset training (Shift-Command-R)")
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

    private var usesPanelBackground: Bool {
        #if os(iOS)
            !compact && horizontalSizeClass != .compact
        #else
            true
        #endif
    }
}

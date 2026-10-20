//
//  EvaluateDetailView.swift
//  ExploreRL
//

import Gymnazo
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct EvaluateDetailView: View {
    let session: SavedSession
    @Bindable var vm: EvaluateViewModel
    var showsCloseButton = true
    var checkpointDirectory: URL? = nil
    var startsOnLoad = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var reloadID = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                agentInfoCard
                if let message = vm.state.status.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Evaluation failed", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                    .foregroundStyle(.red)
                    .accessibilityElement(children: .combine)
                }
                topSection
                if vm.state.status == .completed || !vm.state.episodeRewards.isEmpty {
                    EvaluationSummaryCard(state: vm.state)
                }
                if !vm.state.episodeRewards.isEmpty {
                    EvaluationResults(state: vm.state)
                }
            }
            .frame(maxWidth: AppLayout.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(AppLayout.spacing)
        }
        .navigationTitle(session.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        #if os(iOS)
        .onChange(of: scenePhase, initial: true) { _, phase in
            vm.setEvaluationActive(phase == .active)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            vm.setEvaluationActive(false)
        }
        #endif
        .onDisappear { vm.stopEvaluation() }
        .task(id: "\(session.id)-\(reloadID)-\(isForeground)") {
            guard isForeground else { return }
            await vm.loadSession(session, checkpointDirectory: checkpointDirectory)
            if startsOnLoad, !Task.isCancelled, vm.env != nil { vm.startEvaluation() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if usesBottomControls && vm.state.status == .running {
                EvaluationRunBar(state: vm.state, onStop: vm.stopEvaluation)
            }
        }
    }

    private var isForeground: Bool {
        #if os(iOS)
        scenePhase == .active
        #else
        true
        #endif
    }

    @ViewBuilder
    private var agentInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Agent Info")
                    .font(.headline)
                Spacer()
                AlgorithmBadge(text: session.algorithmType.rawValue)
            }

            LazyVGrid(
                columns: dynamicTypeSize.isAccessibilitySize
                    ? [GridItem(.flexible())]
                    : [GridItem(.adaptive(minimum: 240))],
                alignment: .leading,
                spacing: 8
            ) {
                LabeledContent("Environment", value: session.environmentID)
                LabeledContent("Steps Trained", value: "\(session.trainingState.currentTimestep)")
                LabeledContent("Episodes Trained", value: "\(session.trainingState.episodeCount)")
                if let reward = session.trainingState.meanReward {
                    LabeledContent("Training Avg Reward", value: String(format: "%.2f", reward))
                }
            }
            .font(.subheadline)
            .labeledContentStyle(AdaptiveLabeledContentStyle())
        }
        .padding(AppLayout.panelPadding)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
        )
    }

    @ViewBuilder
    private var topSection: some View {
        if vm.state.renderEnabled, let env = vm.env {
            ViewThatFits(in: .horizontal) {
                if !dynamicTypeSize.isAccessibilitySize {
                    HStack(alignment: .top, spacing: 20) {
                        envSection(env: env)
                            .frame(minWidth: 320, idealWidth: 560, maxWidth: .infinity)
                            .layoutPriority(1)
                        controlsCard
                            .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
                    }
                }

                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    envSection(env: env)
                        .frame(maxWidth: .infinity, alignment: .center)
                    controlsCard
                }
            }
        } else {
            controlsCard
        }
    }

    @ViewBuilder
    private func envSection(env: any Env) -> some View {
        EnvView(
            env: env,
            snapshot: vm.renderSnapshot,
            renderVersion: vm.state.renderVersion
        )
    }

    @ViewBuilder
    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evaluation")
                .font(.headline)

            if vm.state.status == .running {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Episode \(vm.state.currentEpisode + 1) / \(vm.state.totalEpisodes)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .monospacedDigit()
                        Spacer()
                        Text(String(format: "%.0f%%", vm.state.progress * 100))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressView(value: vm.state.progress)
                        .tint(.green)

                    HStack {
                        Text("Step: \(vm.state.currentStep)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }

            settingsRow
            if !usesBottomControls || vm.state.status != .running {
                actionButtons
            }
        }
        .padding(AppLayout.panelPadding)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
        )
    }

    @ViewBuilder
    private var settingsRow: some View {
        let isRunning = vm.state.status == .running
        let isLoading = vm.state.status == .loading

        VStack(alignment: .leading, spacing: 12) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout())
            layout {
                Stepper(
                    "Episodes: \(vm.state.totalEpisodes)",
                    value: $vm.state.totalEpisodes,
                    in: 1...100
                )
                .font(.subheadline)
                .disabled(isRunning || isLoading)

                if !dynamicTypeSize.isAccessibilitySize { Spacer() }

                Toggle("Render", isOn: $vm.state.renderEnabled)
                    .font(.subheadline)
                    .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: true)
                    .disabled(isRunning || isLoading)
            }

            if vm.state.renderEnabled {
                let sliderBinding = Binding<Double>(
                    get: { vm.state.renderFPS <= 0 ? 121 : Double(min(120, vm.state.renderFPS)) },
                    set: { value in
                        let v = Int(value.rounded())
                        vm.state.renderFPS = v >= 121 ? 0 : max(1, min(120, v))
                    }
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("FPS")
                            .font(.subheadline)
                        Spacer()
                        Text(vm.state.renderFPS <= 0 ? "Unlimited" : "\(vm.state.renderFPS) fps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: sliderBinding, in: 1...121)
                        .disabled(isRunning || isLoading)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            switch vm.state.status {
            case .running:
                Button {
                    vm.stopEvaluation()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .modify { button in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        button
                            .buttonStyle(.glass(.regular.tint(.red).interactive()))
                            .controlSize(.large)
                            #if os(macOS)
                                .tint(.red)
                            #endif
                    } else {
                        button
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .tint(.red)
                    }
                }

            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)

            case .failed:
                Button("Reload Agent", systemImage: "arrow.clockwise") {
                    reloadID += 1
                }
                .modify { button in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        button
                            .buttonStyle(.glass(.regular.tint(.blue).interactive()))
                            #if os(macOS)
                                .tint(.blue)
                            #endif
                    } else {
                        button.buttonStyle(.borderedProminent)
                    }
                }
                .controlSize(.large)

            default:
                Button {
                    vm.startEvaluation()
                } label: {
                    Label("Run Evaluation", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(vm.env == nil)
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
                            .controlSize(.large)
                            .tint(.green)
                    }
                }
            }
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

    private var usesBottomControls: Bool {
        #if os(iOS)
            horizontalSizeClass == .compact
        #else
            false
        #endif
    }
}

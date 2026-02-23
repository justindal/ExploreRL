//
//  TrainDetailView.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-03.
//

import Gymnazo
import SwiftUI

struct TrainDetailView: View {

    @State private var showInfo: Bool = false
    @State private var showSettings: Bool = false
    @State private var showSaveSheet: Bool = false
    @State private var showLoadSheet: Bool = false
    @State private var persistenceError: String?
    @State private var isLoadingSession: Bool = false
    @State private var showResetAlert: Bool = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    let id: String
    @Bindable var vm: TrainViewModel

    private var trainingConfig: TrainingConfig {
        vm.trainingConfigs[id] ?? EnvironmentDefaults.config(for: id)
    }

    private var trainingState: TrainingState {
        vm.trainingStates[id] ?? TrainingState()
    }

    var body: some View {
        Group {
            switch vm.envStates[id] ?? .idle {
            case .idle, .loading:
                ProgressView("Loading \(id)...")
            case .loaded(let env):
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        topSection(env: env)
                        if trainingState.status != .idle {
                            TrainingChartsSection(state: trainingState)
                        }
                    }
                    .frame(maxWidth: 960, alignment: .leading)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .overlay {
                    if vm.reloadingEnvs.contains(id) {
                        reloadingOverlay
                    }
                }
            case .error(let error):
                ContentUnavailableView(
                    "Failed to load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            }
        }
        .navigationTitle(id)
        .toolbar {

            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                        showSaveSheet = true
                    } label: {
                        Label(
                            "Save Session",
                            systemImage: "square.and.arrow.down"
                        )
                    }
                    .disabled(
                        trainingState.status == .training
                            || trainingState.currentTimestep == 0
                    )

                    Button {
                        showLoadSheet = true
                    } label: {
                        Label(
                            "Load Session",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .disabled(trainingState.status == .training)
                } label: {
                    Image(systemName: "archivebox")
                }
                .disabled(trainingState.status == .training)
            }

            if #available(iOS 26.0, *), #available(macOS 26.0, *) {
                ToolbarSpacer()
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }
                .disabled(trainingState.status == .training)
            }
        }
        .sheet(
            isPresented: $showSettings,
            content: {
                TrainSettingsView(envID: id, vm: vm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
        )
        .sheet(
            isPresented: $showInfo,
            content: {
                EnvironmentInfo(env: vm.env(for: id))
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
        )
        .sheet(isPresented: $showSaveSheet) {
            SaveSessionSheet(
                environmentID: id,
                algorithmType: trainingConfig.algorithm
            ) { name in
                try await vm.saveSession(for: id, name: name)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLoadSheet) {
            LoadSessionSheet(environmentID: id) { session in
                isLoadingSession = true
                Task {
                    do {
                        try await vm.loadSession(session)
                    } catch {
                        persistenceError = error.localizedDescription
                    }
                    isLoadingSession = false
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .overlay {
            if isLoadingSession {
                loadingOverlay
            }
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { persistenceError != nil },
                set: { if !$0 { persistenceError = nil } }
            )
        ) {
            Button("OK") { persistenceError = nil }
        } message: {
            Text(persistenceError ?? "")
        }
        .alert("Reset training?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                performReset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will clear training progress and reload the environment."
            )
        }
        .task(id: id) {
            await vm.loadEnv(id: id)
        }
    }

    @ViewBuilder
    private func topSection(env: any Env) -> some View {
        if sizeClass == .regular {
            HStack(alignment: .top, spacing: 20) {
                envSection(env: env)
                sidePanel
            }
        } else {
            envSection(env: env)
                .frame(maxWidth: .infinity)
            trainingControlsSection
            if trainingState.status != .idle {
                metricsSection
            }
        }
    }

    @ViewBuilder
    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            trainingContent
            if trainingState.status != .idle {
                Divider()
                metricsContent
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
    }

    @ViewBuilder
    private func envSection(env: any Env) -> some View {
        EnvView(
            env: env,
            snapshot: vm.renderSnapshots[id],
            renderVersion: trainingState.renderVersion
        )
        .id(id)
    }

    @ViewBuilder
    private var trainingControlsSection: some View {
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
    }

    @ViewBuilder
    private var actionBar: some View {
        switch trainingState.status {
        case .training:
            actionRow(primary: pauseButton, secondary: resetButton)
        case .paused:
            actionRow(primary: startButton, secondary: resetButton)
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
            HStack {
                Text(
                    "\(trainingState.currentTimestep) / \(trainingConfig.totalTimesteps) steps"
                )
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
        let viewModel = vm
        let elapsed = viewModel.activeTrainingElapsed(for: id)
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
                performReset()
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

    private var hasTrainingProgress: Bool {
        trainingState.currentTimestep > 0 || trainingState.episodeCount > 0
    }

    private var isResetting: Bool {
        vm.isResetting(id: id)
    }

    private func performReset() {
        Task { await vm.resetTraining(for: id) }
    }

    @ViewBuilder
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricsContent
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var metricsContent: some View {
        Text("Metrics")
            .font(.headline)

        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120))],
            spacing: 12
        ) {
            MetricCard(
                title: "Episodes",
                value: "\(trainingState.episodeCount)"
            )
            MetricCard(
                title: "Avg Reward",
                value: trainingState.meanReward.map {
                    String(format: "%.2f", $0)
                } ?? "-"
            )
            MetricCard(
                title: "Best Reward",
                value: trainingState.rewardHistory.max().map {
                    String(format: "%.2f", $0)
                } ?? "-"
            )
            MetricCard(
                title: "Avg Length",
                value: trainingState.meanEpisodeLength.map {
                    String(format: "%.1f", $0)
                } ?? "-"
            )
            if trainingState.explorationRate != nil {
                MetricCard(
                    title: "Exploration",
                    value: trainingState.explorationRate.map {
                        String(format: "%.1f%%", $0 * 100)
                    } ?? "-"
                )
            }
            if let loss = trainingState.lossHistory.last {
                MetricCard(
                    title: "Loss",
                    value: String(format: "%.4f", loss)
                )
            }
            if let qValue = trainingState.qValueHistory.last {
                MetricCard(
                    title: "Avg Q-Value",
                    value: String(format: "%.2f", qValue)
                )
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Loading session...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
    }

    private var reloadingOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Applying settings...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
    }
}

#Preview {
    TrainDetailView(id: "CartPole", vm: TrainViewModel())
}

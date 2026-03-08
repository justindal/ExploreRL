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
                        if trainingState.hasHistory {
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
        let showsMetrics = trainingState.status != .idle || trainingState.hasHistory
        if sizeClass == .regular {
            if showsMetrics {
                HStack(alignment: .top, spacing: 20) {
                    envSection(env: env)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 600)

                    TrainingMetricsView(
                        trainingState: trainingState,
                        algorithm: trainingConfig.algorithm
                    )
                        .frame(maxWidth: .infinity, alignment: .top)
                }

                TrainingControlsView(
                    id: id,
                    vm: vm,
                    trainingConfig: trainingConfig,
                    trainingState: trainingState,
                    showResetAlert: $showResetAlert
                )
            } else {
                VStack(spacing: 16) {
                    envSection(env: env)
                        .fixedSize(horizontal: false, vertical: true)

                    TrainingControlsView(
                        id: id,
                        vm: vm,
                        trainingConfig: trainingConfig,
                        trainingState: trainingState,
                        showResetAlert: $showResetAlert
                    )
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            envSection(env: env)
                .frame(maxWidth: .infinity)
            TrainingControlsView(
                id: id,
                vm: vm,
                trainingConfig: trainingConfig,
                trainingState: trainingState,
                showResetAlert: $showResetAlert
            )
            if showsMetrics {
                TrainingMetricsView(
                    trainingState: trainingState,
                    algorithm: trainingConfig.algorithm
                )
            }
        }
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

    private func performReset() {
        Task { await vm.resetTraining(for: id) }
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

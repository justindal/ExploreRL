import Gymnazo
import SwiftUI

struct TrainDetailView: View {

    @State private var showEvaluation = false
    @State private var timingDate = Date.now
    @State private var showInfo: Bool = false
    @State private var showSettings: Bool = false
    @State private var showSaveSheet: Bool = false
    @State private var showLoadSheet: Bool = false
    @State private var persistenceError: String?
    @State private var isLoadingSession: Bool = false
    @State private var showResetAlert: Bool = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    let id: String
    @Bindable var vm: TrainViewModel
    var showSettingsInspector: Binding<Bool>? = nil

    private var trainingConfig: TrainingConfig {
        vm.trainingConfigs[id] ?? EnvironmentDefaults.config(for: id)
    }

    private var trainingState: TrainingState {
        vm.trainingStates[id] ?? TrainingState()
    }

    private var navigationTitleText: String {
        vm.env(for: id)?.spec?.displayName ?? id
    }

    private var usesSettingsInspector: Bool {
        showSettingsInspector != nil
    }

    var body: some View {
        mainContent
            .navigationTitle(navigationTitleText)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSettings) {
                TrainSettingsView(
                    envID: id,
                    vm: vm,
                    showsDismissButton: true
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $showEvaluation) {
                TrainingEvaluationSheet(id: id, train: vm)
            }
            .sheet(isPresented: $showInfo) {
                EnvironmentInfo(env: vm.env(for: id))
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
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
            .task(id: trainingState.status == .training) {
                while trainingState.status == .training && !Task.isCancelled {
                    timingDate = .now
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            .task(id: id) {
                await vm.loadEnv(id: id)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if usesBottomControls,
                    trainingState.status != .idle,
                    vm.env(for: id) != nil
                {
                    compactControls
                }
            }
    }

    private var mainContent: some View {
        Group {
            switch vm.envStates[id] ?? .idle {
            case .idle, .loading:
                ProgressView("Loading \(id)...")
            case .loaded(let env):
                GeometryReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                            if usesBottomControls && dynamicTypeSize.isAccessibilitySize,
                                trainingState.status != .idle,
                                trainingConfig.renderDuringTraining
                            {
                                TrainingProgressView(
                                    id: id, vm: vm, trainingConfig: trainingConfig,
                                    trainingState: trainingState
                                )
                            }
                            topSection(
                                env: env,
                                availableWidth: max(0, proxy.size.width - AppLayout.spacing * 2)
                            )
                            if trainingState.hasHistory {
                                TrainingChartsSection(state: trainingState)
                            }
                        }
                        .frame(
                            minHeight: minimumContentHeight(for: proxy.size.height),
                            alignment: renderDisabledContentIsCentered ? .center : .top
                        )
                        .frame(maxWidth: AppLayout.contentMaxWidth, alignment: .leading)
                        .frame(maxWidth: .infinity)
                        .padding(AppLayout.spacing)
                    }
                    .overlay {
                        if vm.reloadingEnvs.contains(id) {
                            reloadingOverlay
                        }
                    }
                }
            case .error(let error):
                ContentUnavailableView {
                    Label("Failed to load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Retry", systemImage: "arrow.clockwise") {
                        Task { await vm.loadEnv(id: id) }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if trainingState.currentTimestep > 0 && trainingState.status != .training {
            ToolbarItem(placement: toolbarPlacement) {
                Button("Evaluate This Run", systemImage: "play.circle") { showEvaluation = true }
                    .labelStyle(.iconOnly)
                    .disabled(!vm.canSnapshot(id))
                    .help("Evaluate a snapshot of the current run")
            }
        }

        ToolbarItem(placement: toolbarPlacement) {
            Menu("Session", systemImage: "archivebox") {
                Button {
                    showSaveSheet = true
                } label: {
                    Label(
                        "Save Session",
                        systemImage: "square.and.arrow.down"
                    )
                }
                .disabled(
                    !vm.canSnapshot(id)
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
            }
            .labelStyle(.iconOnly)
            .disabled(trainingState.status == .training)
        }

        ToolbarItem(placement: toolbarPlacement) {
            Button("Environment Info", systemImage: "info.circle") {
                showInfo.toggle()
            }
            .labelStyle(.iconOnly)
        }
        ToolbarItem(placement: toolbarPlacement) {
            Button(
                usesSettingsInspector ? "Toggle Settings" : "Settings",
                systemImage: usesSettingsInspector ? "sidebar.right" : "gearshape"
            ) {
                if let binding = showSettingsInspector {
                    binding.wrappedValue.toggle()
                } else {
                    showSettings = true
                }
            }
            .labelStyle(.iconOnly)
        }
    }

    #if os(iOS)
        private var toolbarPlacement: ToolbarItemPlacement { .topBarTrailing }
    #else
        private var toolbarPlacement: ToolbarItemPlacement { .automatic }
    #endif

    @ViewBuilder
    private func topSection(env: any Env, availableWidth: CGFloat) -> some View {
        let showsMetrics =
            trainingState.status != .idle || trainingState.hasHistory
        let showControlsProgress = trainingConfig.renderDuringTraining
        let showsInlineControls = !usesBottomControls || trainingState.status == .idle
        let prefersCenteredRenderer = id.hasPrefix("Snake")
        if showsMetrics {
            if prefersCenteredRenderer || availableWidth < 820 || dynamicTypeSize.isAccessibilitySize {
                stackedTrainingWorkspace(
                    env: env,
                    showControlsProgress: showControlsProgress,
                    showsControls: showsInlineControls
                )
            } else {
                wideTrainingWorkspace(
                    env: env,
                    showControlsProgress: showControlsProgress,
                    showsControls: showsInlineControls
                )
            }
        } else {
            VStack(spacing: 16) {
                envSection(env: env)
                    .frame(maxWidth: .infinity, alignment: .center)

                if showsInlineControls {
                    TrainingControlsView(
                        id: id,
                        vm: vm,
                        trainingConfig: trainingConfig,
                        trainingState: trainingState,
                        showResetAlert: $showResetAlert,
                        showDetailedProgress: showControlsProgress
                    )
                }
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func wideTrainingWorkspace(
        env: any Env,
        showControlsProgress: Bool,
        showsControls: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                envSection(env: env)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .layoutPriority(1)

                TrainingMetricsView(
                    trainingState: trainingState,
                    algorithm: trainingConfig.algorithm
                )
                .frame(minWidth: 280, idealWidth: 340, maxWidth: 420)
            }

            if showsControls {
                TrainingControlsView(
                    id: id,
                    vm: vm,
                    trainingConfig: trainingConfig,
                    trainingState: trainingState,
                    showResetAlert: $showResetAlert,
                    showDetailedProgress: showControlsProgress
                )
            }
        }
    }

    private func stackedTrainingWorkspace(
        env: any Env,
        showControlsProgress: Bool,
        showsControls: Bool
    ) -> some View {
        VStack(alignment: .center, spacing: 16) {
            envSection(env: env)
                .frame(maxWidth: .infinity, alignment: .center)

            if showsControls {
                TrainingControlsView(
                    id: id,
                    vm: vm,
                    trainingConfig: trainingConfig,
                    trainingState: trainingState,
                    showResetAlert: $showResetAlert,
                    showDetailedProgress: showControlsProgress
                )
            }

            TrainingMetricsView(
                trainingState: trainingState,
                algorithm: trainingConfig.algorithm
            )
        }
    }

    @ViewBuilder
    private func envSection(env: any Env) -> some View {
        let content = EnvView(
            env: env,
            snapshot: vm.renderSnapshots[id],
            renderVersion: trainingState.renderVersion,
            renderDuringTraining: trainingConfig.renderDuringTraining,
            trainingState: trainingState,
            trainingConfig: trainingConfig,
            elapsed: vm.trainingTimings[id]?.activeElapsed(now: timingDate) ?? 0,
            timedSteps: vm.timedTrainingSteps(for: id)
        )

        #if os(iOS)
            if horizontalSizeClass == .compact {
                content
                    .frame(maxWidth: 360)
                    .frame(maxWidth: .infinity)
                    .id(id)
            } else {
                content
                    .frame(maxWidth: .infinity)
                    .id(id)
            }
        #else
            content
                .id(id)
        #endif
    }

    private func performReset() {
        Task { await vm.resetTraining(for: id) }
    }

    private var usesBottomControls: Bool {
        #if os(iOS)
            horizontalSizeClass == .compact
        #else
            false
        #endif
    }

    private var renderDisabledContentIsCentered: Bool {
        #if os(iOS)
            horizontalSizeClass == .compact && !trainingConfig.renderDuringTraining
        #else
            false
        #endif
    }

    private func minimumContentHeight(for availableHeight: CGFloat) -> CGFloat {
        guard renderDisabledContentIsCentered else { return 0 }
        return max(0, availableHeight - (AppLayout.spacing * 2))
    }

    private var compactControls: some View {
        TrainingControlsView(
            id: id,
            vm: vm,
            trainingConfig: trainingConfig,
            trainingState: trainingState,
            showResetAlert: $showResetAlert,
            showDetailedProgress: trainingConfig.renderDuringTraining,
            compact: true
        )
        .padding(.horizontal, AppLayout.spacing)
        .padding(.vertical, AppLayout.compactSpacing)
        .frame(maxWidth: .infinity)
        .background(.background)
        .overlay(alignment: .top) {
            Divider()
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
    TrainDetailView(
        id: "CartPole",
        vm: TrainViewModel()
    )
}

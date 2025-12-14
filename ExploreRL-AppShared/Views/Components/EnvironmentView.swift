//
//  EnvironmentView.swift
//

import SwiftUI

/// A generic environment view that handles all common UI logic for RL environment training.
struct EnvironmentView<Runner: SavableEnvironmentRunner, CanvasView: View, ConfigView: View, ChartsView: View, InfoView: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var runner: Runner
    
    let environmentName: String
    let environmentType: EnvironmentType
    let algorithmType: String
    let accentColor: Color
    let canvasAspectRatio: CGFloat
    let canvasMaxSize: CGSize
    
    @ViewBuilder let canvas: (Runner.SnapshotType?) -> CanvasView
    @ViewBuilder let configuration: () -> ConfigView
    @ViewBuilder let charts: ([GridItem]?) -> ChartsView
    @ViewBuilder let info: () -> InfoView
    
    var showPolicyOverlay: (() -> AnyView)? = nil
    
    @State private var showInspector = true
    @State private var selectedTab: InspectorTab = .settings
    @State private var showSaveSheet = false
    @State private var showLoadSheet = false
    @State private var showUnsavedChangesAlert = false
    @State private var showLeaveUnsavedAlert = false
    @State private var showResetConfirmation = false
    @State private var showTrainingCompleteBanner = false
    
    enum InspectorTab: String, CaseIterable, Identifiable {
        case settings = "Settings"
        case charts = "Charts"
        case info = "Info"
        var id: String { rawValue }
    }
    
    private var hasUnsavedChanges: Bool {
        runner.episodeCount > 1 && (runner.loadedAgentId == nil || runner.hasTrainedSinceLoad)
    }
    
    init(
        runner: Runner,
        environmentName: String,
        environmentType: EnvironmentType,
        algorithmType: String,
        accentColor: Color,
        canvasAspectRatio: CGFloat,
        canvasMaxSize: CGSize,
        @ViewBuilder canvas: @escaping (Runner.SnapshotType?) -> CanvasView,
        @ViewBuilder configuration: @escaping () -> ConfigView,
        @ViewBuilder charts: @escaping ([GridItem]?) -> ChartsView,
        @ViewBuilder info: @escaping () -> InfoView
    ) {
        self.runner = runner
        self.environmentName = environmentName
        self.environmentType = environmentType
        self.algorithmType = algorithmType
        self.accentColor = accentColor
        self.canvasAspectRatio = canvasAspectRatio
        self.canvasMaxSize = canvasMaxSize
        self.canvas = canvas
        self.configuration = configuration
        self.charts = charts
        self.info = info
    }
    
    var body: some View {
        Group {
            if isCompactLayout {
                compactLayout
            } else {
                regularLayout
            }
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showSaveSheet) { saveSheet }
        .sheet(isPresented: $showLoadSheet) { loadSheet }
        .alert("Unsaved Training Progress", isPresented: $showUnsavedChangesAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save First") { showSaveSheet = true }
            Button("Discard & Load", role: .destructive) { showLoadSheet = true }
        } message: {
            Text("You have unsaved training progress. Loading a new agent will discard your current progress.")
        }
        .alert("Unsaved Changes", isPresented: $showLeaveUnsavedAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save & Leave") { showSaveSheet = true }
            Button("Leave Without Saving", role: .destructive) { dismiss() }
        } message: {
            Text("You have unsaved training progress. Do you want to save before leaving?")
        }
        .alert("Reset Agent?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { runner.reset() }
        } message: {
            Text("This will reset the agent and clear all training progress. This cannot be undone.")
        }
        .onChange(of: runner.isTraining) { wasTraining, isTraining in
            if wasTraining && !isTraining && runner.runProgress >= 1.0 {
                withAnimation { showTrainingCompleteBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showTrainingCompleteBanner = false }
                }
            }
        }
        .overlay(alignment: .top) {
            if runner.isWarmingUp {
                WarmupBanner(progress: runner.warmupProgress, color: accentColor)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .animation(.easeInOut, value: runner.warmupProgress)
            } else if showTrainingCompleteBanner {
                TrainingCompleteBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut, value: runner.isWarmingUp)
        #if os(iOS)
        .navigationBarBackButtonHidden(runner.isTraining || hasUnsavedChanges)
        .toolbar {
            if hasUnsavedChanges && !runner.isTraining {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showLeaveUnsavedAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
        #endif
        .interactiveDismissDisabled(runner.isTraining || hasUnsavedChanges)
        #if os(iOS)
        .navigationTitle(environmentName)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var isCompactLayout: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact || verticalSizeClass == .compact
        #else
        return horizontalSizeClass == .compact
        #endif
    }
    
    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 20) {
                environmentHeader
                    .padding(.horizontal, 4)
                
                environmentCanvas
                
                environmentControls
                
                if showInspector {
                    Divider()
                    inspectorView
                }
            }
            .padding()
        }
    }
    
    private var regularLayout: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    environmentHeader
                    environmentCanvas
                    environmentControls
                    Spacer()
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            
            if showInspector {
                Divider()
                
                inspectorView
                    .frame(width: 320)
                    #if os(macOS)
                    .background(.background)
                    #else
                    .background(Color(UIColor.secondarySystemBackground))
                    #endif
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                if hasUnsavedChanges {
                    showUnsavedChangesAlert = true
                } else {
                    showLoadSheet = true
                }
            } label: {
                Label("Load", systemImage: "tray.and.arrow.down")
            }
            .disabled(runner.isTraining)
            
            Button {
                showSaveSheet = true
            } label: {
                Label("Save", systemImage: "tray.and.arrow.up")
            }
            .disabled(runner.isTraining || runner.episodeCount <= 1)
            
            Toggle(isOn: $showInspector) {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .toggleStyle(.button)
        }
    }
    
    private var saveSheet: some View {
        SaveAgentSheet(
            environmentType: environmentType,
            algorithmType: algorithmType,
            episodesTrained: runner.totalEpisodesTrained,
            currentReward: runner.averageReward,
            loadedAgentId: runner.loadedAgentId,
            loadedAgentName: runner.loadedAgentName,
            onSave: { name in
                try runner.saveAgent(name: name)
            },
            onUpdate: runner.loadedAgentId != nil ? { id, name in
                try runner.updateAgent(id: id, name: name)
            } : nil
        )
    }
    
    private var loadSheet: some View {
        LoadAgentSheet(environmentType: environmentType) { agent in
            try runner.loadAgent(from: agent)
        }
    }
    
    private var environmentHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom != .phone {
                HStack(alignment: .center) {
                    Text(environmentName)
                        .font(horizontalSizeClass == .compact ? .title : .largeTitle)
                        .bold()
                    
                    if hasUnsavedChanges {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                            .help("Unsaved changes")
                    }
                }
            }
            #else
            HStack(alignment: .center) {
                Text(environmentName)
                    .font(horizontalSizeClass == .compact ? .title : .largeTitle)
                    .bold()
                
                if hasUnsavedChanges {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                        .help("Unsaved changes")
                }
            }
            #endif
            
            if let loadedName = runner.loadedAgentName {
                HStack(spacing: 6) {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                    Text(loadedName)
                        .font(.subheadline)
                    if runner.hasTrainedSinceLoad {
                        Text("• Modified")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            statsRow
                .font(.headline)
                .padding(.top, 5)
        }
    }
    
    private var statsRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                Spacer()
                Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                Spacer()
                rewardLabel
            }
            
            VStack(alignment: .leading) {
                Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                rewardLabel
            }
        }
    }
    
    private var rewardLabel: some View {
        Group {
            if let lastMetric = runner.episodeMetrics.last {
                Label(String(format: "Reward: %.0f", lastMetric.reward), systemImage: "trophy")
            } else {
                Label("Reward: 0", systemImage: "trophy")
            }
        }
    }
    
    private var environmentCanvas: some View {
        ZStack {
            if runner.renderEnabled {
                renderView
            } else {
                chartsCanvas
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var renderView: some View {
        if let snapshot = runner.snapshot {
            canvas(snapshot)
                .aspectRatio(canvasAspectRatio, contentMode: .fit)
                .frame(maxWidth: canvasMaxSize.width, maxHeight: canvasMaxSize.height)
                .cornerRadius(12)
                .shadow(radius: 5)
                .overlay {
                    if let overlay = showPolicyOverlay {
                        overlay()
                    }
                }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(canvasAspectRatio, contentMode: .fit)
                .frame(maxWidth: canvasMaxSize.width)
                .overlay(Text("Initializing Environment..."))
                .cornerRadius(12)
        }
    }
    
    private var chartsCanvas: some View {
        ScrollView {
            charts([
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ])
            .frame(maxWidth: 700)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
    }
    
    private var environmentControls: some View {
        VStack(spacing: 12) {
            TrainingProgressView(
                current: runner.episodeMetrics.count,
                total: runner.episodesPerRun,
                totalEpisodesTrained: runner.totalEpisodesTrained,
                accumulatedTrainingTimeSeconds: runner.accumulatedTrainingTimeSeconds,
                trainingSessionStartDate: runner.trainingSessionStartDate,
                isTraining: runner.isTraining,
                color: accentColor
            )
            .padding(.horizontal, 40)
            
            controlButtons
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            if runner.isTraining {
                Button(action: { runner.stopTraining() }) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(minWidth: 120)
                }
                .buttonStyle(TrainingButtonStyle(color: .red))
                .accessibilityLabel("Stop Training")
                .accessibilityHint("Stops the current training session")
            } else {
                Button(action: { runner.startTraining() }) {
                    Label(runner.canResume ? "Resume Training" : "Start Training", systemImage: "play.fill")
                        .font(.headline)
                        .frame(minWidth: 140)
                }
                .buttonStyle(TrainingButtonStyle(color: accentColor))
                .accessibilityLabel(runner.canResume ? "Resume Training" : "Start Training")
                .accessibilityHint("Begins training the \(environmentName) agent")
                
                Button(action: {
                    if hasUnsavedChanges {
                        showResetConfirmation = true
                    } else {
                        runner.reset()
                    }
                }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(minWidth: 100)
                }
                .buttonStyle(TrainingButtonStyle(color: Color(.systemGray)))
                .accessibilityLabel("Reset Agent")
                .accessibilityHint("Resets the agent to initial state")
            }
        }
    }
    
    private var inspectorView: some View {
        VStack(spacing: 15) {
            Picker("", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                Group {
                    if selectedTab == .settings {
                        configuration()
                    } else if selectedTab == .charts {
                        charts(nil)
                    } else {
                        info()
                    }
                }
                .id(selectedTab)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipped()
        }
    }
}

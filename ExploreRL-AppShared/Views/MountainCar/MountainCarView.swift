//
//  MountainCarView.swift
//

import SwiftUI
import Gymnazo

struct MountainCarView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var runner: MountainCarRunner
    
    @State private var showInspector = true
    @State private var selectedTab: InspectorTab = .settings
    @State private var showSaveSheet = false
    @State private var showLoadSheet = false
    @State private var showUnsavedChangesAlert = false
    @State private var showLeaveUnsavedAlert = false
    @State private var showResetConfirmation = false
    @State private var showTrainingCompleteBanner = false
    
    private var hasUnsavedChanges: Bool {
        runner.episodeCount > 1 && (runner.loadedAgentId == nil || runner.hasTrainedSinceLoad)
    }
    
    enum InspectorTab: String, CaseIterable, Identifiable {
        case settings = "Settings"
        case charts = "Charts"
        var id: String { rawValue }
    }
    
    var body: some View {
        mainContent
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSaveSheet) {
                SaveAgentSheet(
                    environmentType: .mountainCar,
                    algorithmType: "DQN",
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
            .sheet(isPresented: $showLoadSheet) {
                LoadAgentSheet(environmentType: .mountainCar) { agent in
                    try runner.loadAgent(from: agent)
                }
            }
            .alert("Unsaved Training Progress", isPresented: $showUnsavedChangesAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Save First") {
                    showSaveSheet = true
                }
                Button("Discard & Load", role: .destructive) {
                    showLoadSheet = true
                }
            } message: {
                Text("You have unsaved training progress. Loading a new agent will discard your current progress.")
            }
            .alert("Unsaved Changes", isPresented: $showLeaveUnsavedAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Save & Leave") {
                    showSaveSheet = true
                }
                Button("Leave Without Saving", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved training progress. Do you want to save before leaving?")
            }
            .alert("Reset Agent?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    runner.reset()
                }
            } message: {
                Text("This will reset the agent and clear all training progress. This cannot be undone.")
            }
            .onChange(of: runner.isTraining) { wasTraining, isTraining in
                if wasTraining && !isTraining && runner.runProgress >= 1.0 {
                    withAnimation {
                        showTrainingCompleteBanner = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showTrainingCompleteBanner = false
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                if showTrainingCompleteBanner {
                    TrainingCompleteBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Mountain Car")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(runner.isTraining)
            #endif
            .interactiveDismissDisabled(runner.isTraining)
    }
    
    
    @ViewBuilder
    private var mainContent: some View {
        if horizontalSizeClass == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }
    
    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 20) {
                EnvironmentHeader()
                    .padding(.horizontal, 4)
                EnvironmentCanvas()
                EnvironmentControls()
                if showInspector {
                    Divider()
                    InspectorView()
                }
            }
            .padding()
        }
    }
    
    private var regularLayout: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    EnvironmentHeader()
                    EnvironmentCanvas()
                    EnvironmentControls()
                    Spacer()
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            
            if showInspector {
                Divider()
                
                InspectorView()
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
    
    
    @ViewBuilder
    private func InspectorView() -> some View {
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
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .settings:
                        MountainCarConfigurationView(runner: runner)
                            .transition(.move(edge: .leading))
                    case .charts:
                        MountainCarChartsView(runner: runner)
                            .transition(.move(edge: .trailing))
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
    }
    
    @ViewBuilder
    private func EnvironmentHeader() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("Mountain Car")
                    .font(horizontalSizeClass == .compact ? .title : .largeTitle)
                    .bold()
                
                if hasUnsavedChanges {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                        .help("Unsaved changes")
                }
                
                if let name = runner.loadedAgentName {
                    Text("(\(name))")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            statsView
        }
    }
    
    private var statsView: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                Spacer()
                Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                Spacer()
                Label(String(format: "Reward: %.0f", runner.episodeReward), systemImage: "trophy")
            }
            
            VStack(alignment: .leading) {
                Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                Label(String(format: "Reward: %.0f", runner.episodeReward), systemImage: "trophy")
            }
        }
        .font(.headline)
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private func EnvironmentCanvas() -> some View {
        ZStack {
            if runner.renderEnabled {
                renderView
            } else {
                chartsView
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var renderView: some View {
        if let snapshot = runner.snapshot {
            MountainCarCanvasView(snapshot: snapshot)
                .aspectRatio(2.0, contentMode: .fit)
                .frame(maxWidth: 600, maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 5)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(2.0, contentMode: .fit)
                .frame(maxWidth: 600)
                .overlay(Text("Initializing Environment..."))
                .cornerRadius(12)
        }
    }
    
    private var chartsView: some View {
        ScrollView {
            MountainCarChartsView(
                runner: runner,
                columns: [GridItem(.flexible(), spacing: 12),
                          GridItem(.flexible(), spacing: 12)]
            )
            .frame(maxWidth: 700)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func EnvironmentControls() -> some View {
        VStack(spacing: 12) {
            if !runner.renderEnabled && runner.isTraining {
                progressView
            }
            
            controlButtons
        }
    }
    
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Training Progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(runner.episodeMetrics.count) / \(runner.episodesPerRun)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    let progress = Double(runner.episodeMetrics.count) / Double(max(1, runner.episodesPerRun))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 40)
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
                .buttonStyle(TrainingButtonStyle(color: .green))
                .accessibilityLabel(runner.canResume ? "Resume Training" : "Start Training")
                .accessibilityHint("Begins training the Mountain Car agent")
                
                Button(action: {
                    if runner.episodeMetrics.count > 0 {
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
}

struct MountainCarCanvasView: View {
    let snapshot: MountainCarSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.MountainCarView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}

#Preview {
    MountainCarView(runner: MountainCarRunner())
}

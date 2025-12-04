//
//  AcrobotView.swift
//

import SwiftUI
import Gymnazo

struct AcrobotView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var runner: AcrobotRunner
    
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
        Group {
            // layout for iOS
            if horizontalSizeClass == .compact {
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
            } else {
                // layout for macOS/iPadOS
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
        }
        .toolbar {
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
        .sheet(isPresented: $showSaveSheet) {
            SaveAgentSheet(
                environmentType: .acrobot,
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
            LoadAgentSheet(environmentType: .acrobot) { agent in
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
                        AcrobotConfigurationView(runner: runner)
                            .transition(.move(edge: .leading))
                    case .charts:
                        AcrobotChartsView(runner: runner)
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
                Text("Acrobot")
                    .font(horizontalSizeClass == .compact ? .title : .largeTitle)
                    .bold()
                
                if hasUnsavedChanges {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                        .help("Unsaved changes")
                }
            }
            
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
            
            ViewThatFits(in: .horizontal) {
                HStack {
                    Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                    Spacer()
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    Spacer()
                    if let lastMetric = runner.episodeMetrics.last {
                        Label(String(format: "Reward: %.0f", lastMetric.reward), systemImage: "trophy")
                    } else {
                        Label("Reward: 0", systemImage: "trophy")
                    }
                }
                
                VStack(alignment: .leading) {
                    Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    if let lastMetric = runner.episodeMetrics.last {
                        Label(String(format: "Reward: %.0f", lastMetric.reward), systemImage: "trophy")
                    } else {
                        Label("Reward: 0", systemImage: "trophy")
                    }
                }
            }
            .font(.headline)
            .padding(.top, 5)
        }
    }
    
    @ViewBuilder
    private func EnvironmentCanvas() -> some View {
        ZStack {
            if runner.renderEnabled {
                if let snapshot = runner.snapshot {
                    AcrobotViewAdapter(snapshot: snapshot)
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: 500, maxHeight: 500)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: 500)
                        .overlay(Text("Initializing Environment..."))
                        .cornerRadius(12)
                }
            } else {
                ScrollView {
                    AcrobotChartsView(
                        runner: runner,
                        columns: [GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12)]
                    )
                    .frame(maxWidth: 700)
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func EnvironmentControls() -> some View {
        VStack(spacing: 12) {
            if !runner.renderEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Training Progress")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", runner.runProgress * 100))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                                .frame(width: geometry.size.width * runner.runProgress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 16) {
                if runner.isTraining {
                    Button(action: { runner.stopTraining() }) {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(AcrobotTrainingButtonStyle(color: .red))
                    .accessibilityLabel("Stop Training")
                    .accessibilityHint("Stops the current training session")
                } else {
                    Button(action: { runner.startTraining() }) {
                        Label(runner.canResume ? "Resume Training" : "Start Training", systemImage: "play.fill")
                            .font(.headline)
                            .frame(minWidth: 140)
                    }
                    .buttonStyle(AcrobotTrainingButtonStyle(color: .red))
                    .accessibilityLabel(runner.canResume ? "Resume Training" : "Start Training")
                    .accessibilityHint("Begins training the Acrobot agent")
                    
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
                    .buttonStyle(AcrobotTrainingButtonStyle(color: Color(.systemGray)))
                    .accessibilityLabel("Reset Agent")
                    .accessibilityHint("Resets the agent to initial state")
                }
            }
        }
    }
}

struct AcrobotTrainingButtonStyle: ButtonStyle {
    let color: Color
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.4)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AcrobotViewAdapter: View {
    let snapshot: AcrobotSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.AcrobotView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}

#Preview {
    AcrobotView(runner: AcrobotRunner())
}


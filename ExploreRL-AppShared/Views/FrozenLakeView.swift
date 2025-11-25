//
//  FrozenLakeView.swift
//

import SwiftUI
import Foundation
import Charts
import ExploreRLCore

struct FrozenLakeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var runner = FrozenLakeRunner()
    @State private var showInspector = true
    @State private var selectedTab: InspectorTab = .settings
    @State private var showSaveSheet = false
    @State private var showLoadSheet = false
    @State private var showUnsavedChangesAlert = false
    
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
                    VStack(spacing: 20) {
                        EnvironmentHeader()
                        
                        EnvironmentCanvas()
                        
                        EnvironmentControls()
                        
                        Spacer()
                    }
                    .padding()
                    .frame(minWidth: 400)
                    
                    if showInspector {
                        VStack(spacing: 0) {
                            InspectorView()
                        }
                        .frame(width: 350)
                        .background(Color.gray.opacity(0.05))
                        .border(Color.gray.opacity(0.2), width: 1)
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
                environmentType: .frozenLake,
                algorithmType: runner.selectedAlgorithm.rawValue,
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
            LoadAgentSheet(environmentType: .frozenLake) { agent in
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
        .navigationBarBackButtonHidden(runner.isTraining)
        .interactiveDismissDisabled(runner.isTraining)
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
                        FrozenLakeConfigurationView(runner: runner)
                            .transition(.move(edge: .leading))
                    case .charts:
                        FrozenLakeChartsView(runner: runner)
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
                Text("Frozen Lake")
                    .font(.largeTitle)
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
                    Label("\(max(1, runner.episodeCount)) Episodes", systemImage: "number")
                    Spacer()
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    Spacer()
                    Label(String(format: "Success: %.0f%%", runner.successRate * 100), systemImage: "checkmark.circle")
                }
                
                VStack(alignment: .leading) {
                    Label("\(max(1, runner.episodeCount)) Episodes", systemImage: "number")
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    Label(String(format: "Success: %.0f%%", runner.successRate * 100), systemImage: "checkmark.circle")
                }
            }
            .font(.headline)
            .padding(.top, 5)
        }
    }
    
    @ViewBuilder
    private func EnvironmentCanvas() -> some View {
        ZStack {
            if let snapshot = runner.snapshot {
                FrozenLakeCanvasView(snapshot: snapshot)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: 500, maxHeight: 500)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .overlay {
                        if runner.showPolicy, let policy = runner.currentPolicy {
                            PolicyOverlayView(map: runner.currentMap, policy: policy)
                                .frame(maxWidth: 500, maxHeight: 500)
                                .allowsHitTesting(false) 
                        }
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: 500)
                    .overlay(Text("Initializing Environment..."))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func EnvironmentControls() -> some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Training Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    let progress = min(1.0, Double(runner.episodeMetrics.count) / Double(runner.episodesPerRun))
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                
                GeometryReader { geometry in
                    let progress = min(1.0, Double(runner.episodeMetrics.count) / Double(runner.episodesPerRun))
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 40)
            
            HStack(spacing: 16) {
                if runner.isTraining {
                    Button(action: { runner.stopTraining() }) {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(FrozenLakeButtonStyle(color: .red))
                } else {
                    Button(action: { runner.startTraining() }) {
                        Label(runner.canResume ? "Resume Training" : "Start Training", systemImage: "play.fill")
                            .font(.headline)
                            .frame(minWidth: 140)
                    }
                    .buttonStyle(FrozenLakeButtonStyle(color: .green))
                    
                    Button(action: { runner.reset() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(FrozenLakeButtonStyle(color: Color(.systemGray)))
                }
            }
        }
    }
}

struct FrozenLakeButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    FrozenLakeView()
}

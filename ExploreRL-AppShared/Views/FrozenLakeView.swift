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
    @State private var selectedTab: InspectorTab = .charts
    
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
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $showInspector) {
                    Label("Inspector", systemImage: "sidebar.right")
                }
                .toggleStyle(.button)
            }
        }
        .navigationBarBackButtonHidden(runner.isTraining)
        .interactiveDismissDisabled(runner.isTraining)
    }
    
    @ViewBuilder
    private func InspectorView() -> some View {
        VStack(spacing: 15) {
            Picker("Inspector Mode", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
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
        VStack(alignment: .leading) {
            Text("Frozen Lake")
                .font(.largeTitle)
                .bold()
            
            ViewThatFits(in: .horizontal) {
                HStack {
                    Label("\(max(1, runner.episodeCount)) Episodes", systemImage: "number")
                    Spacer()
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    Spacer()
                    Label(String(format: "Reward: %.0f", runner.totalReward), systemImage: "trophy")
                }
                
                VStack(alignment: .leading) {
                    Label("\(max(1, runner.episodeCount)) Episodes", systemImage: "number")
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    Label(String(format: "Reward: %.0f", runner.totalReward), systemImage: "trophy")
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
        .padding()
    }
    
    @ViewBuilder
    private func EnvironmentControls() -> some View {
        HStack(spacing: 20) {
            if runner.isTraining {
                Button(action: {
                    runner.stopTraining()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .frame(minWidth: 100)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                Button(action: {
                    runner.startTraining()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Training")
                    }
                    .frame(minWidth: 120)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    runner.reset()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .frame(minWidth: 100)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    FrozenLakeView()
}

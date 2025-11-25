//
//  EnvironmentListView.swift
//

import SwiftUI

struct EnvironmentListView: View {
    private var trainingState = TrainingState.shared
    @State private var showTrainingAlert = false
    
    var body: some View {
        NavigationSplitView {
            List {
                Section("Training") {
                    NavigationLink {
                        FrozenLakeView()
                    } label: {
                        HStack {
                            Label("Frozen Lake", systemImage: "snowflake")
                            if trainingState.activeEnvironment == "Frozen Lake" {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(trainingState.isTraining && trainingState.activeEnvironment != "Frozen Lake")
                    
                    NavigationLink {
                        CartPoleView()
                    } label: {
                        HStack {
                            Label("Cart Pole", systemImage: "cart")
                            if trainingState.activeEnvironment == "Cart Pole" {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(trainingState.isTraining && trainingState.activeEnvironment != "Cart Pole")
                }
                
                if trainingState.isTraining, let env = trainingState.activeEnvironment {
                    Section {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.orange)
                            Text("Training \(env)...")
                                .foregroundStyle(.secondary)
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                
                Section("Evaluate") {
                    NavigationLink {
                        EvaluationView()
                    } label: {
                        Label("Evaluation Mode", systemImage: "play.circle")
                    }
                    .disabled(trainingState.isTraining)
                }
                
                Section("Library") {
                    NavigationLink {
                        SavedAgentsView()
                    } label: {
                        Label("Saved Agents", systemImage: "tray.full")
                    }
                    .disabled(trainingState.isTraining)
                }
            }
            .navigationTitle("ExploreRL")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            #endif
        } detail: {
            Text("Select an Environment")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    EnvironmentListView()
}


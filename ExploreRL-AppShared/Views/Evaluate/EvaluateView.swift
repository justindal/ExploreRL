//
//  EvaluateView.swift
//

import SwiftUI

struct EvaluateView: View {
    @Bindable var runner: EvaluationRunner
    @State private var storage = AgentStorage.shared
    @State private var isLoading = true
    @State private var agentsCache: [EnvironmentType: [SavedAgentSummary]] = [:]
    
    var body: some View {
        NavigationStack {
            Group {
                if runner.loadedAgent != nil {
                    EvaluationContentView(runner: runner) {
                        runner.reset()
                    }
                } else if isLoading {
                    ProgressView("Loading agents...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if storage.savedAgents.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Agents", systemImage: "tray")
                    } description: {
                        Text("Train an agent and save it to evaluate later.")
                    }
                } else {
                    agentListView
                }
            }
            .navigationTitle("Evaluate")
            .task {
                await loadAgents()
            }
            .refreshable {
                await loadAgents()
            }
        }
    }
    
    private func loadAgents() async {
        isLoading = true
        storage.loadAgentList()
        for envType in EnvironmentType.allCases {
            agentsCache[envType] = storage.agents(for: envType)
        }
        isLoading = false
    }
    
    private var agentListView: some View {
        List {
            ForEach(EnvironmentType.allCases, id: \.self) { envType in
                let agents = agentsCache[envType] ?? []
                if !agents.isEmpty {
                    Section {
                        ForEach(agents) { agent in
                            Button {
                                loadAgent(agent)
                            } label: {
                                EvaluateAgentRow(agent: agent)
                            }
                        }
                    } header: {
                        HStack(spacing: 8) {
                            Image(systemName: envType.iconName)
                                .foregroundStyle(envType.accentColor)
                            Text(envType.displayName)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(agents.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .textCase(nil)
                    }
                }
            }
        }
    }
    
    private func loadAgent(_ agentSummary: SavedAgentSummary) {
        do {
            let fullAgent = try storage.loadAgent(id: agentSummary.id)
            try runner.loadAgent(fullAgent)
        } catch {
            print("Failed to load agent: \(error)")
        }
    }
}

struct EvaluateAgentRow: View {
    let agent: SavedAgentSummary
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(agent.algorithmType)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    
                    Text("\(agent.episodesTrained) ep")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let successRate = agent.successRate {
                    Text(String(format: "%.0f%%", successRate * 100))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                } else {
                    Text(String(format: "%.0f", agent.bestReward))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EvaluateView(runner: EvaluationRunner())
}


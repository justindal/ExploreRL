//
//  LoadAgentSheet.swift
//

import SwiftUI

struct LoadAgentSheet: View {
    let environmentType: EnvironmentType
    let onLoad: (SavedAgent) throws -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var storage = AgentStorage.shared
    @State private var selectedAgent: SavedAgentSummary?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var availableAgents: [SavedAgentSummary] {
        storage.agents(for: environmentType)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if availableAgents.isEmpty {
                    emptyStateView
                } else {
                    agentListView
                }
            }
            .navigationTitle("Load Agent")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                storage.loadAgentList()
            }
        }
        #if os(macOS)
        .frame(minWidth: 450, minHeight: 400)
        #endif
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Saved Agents")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("You haven't saved any \(environmentType.displayName) agents yet.\nTrain an agent and save it to load it later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var agentListView: some View {
        VStack(spacing: 0) {
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.subheadline)
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }
            
            List(availableAgents, selection: $selectedAgent) { agent in
                LoadAgentRow(agent: agent) {
                    loadAgent(agent)
                }
            }
            .listStyle(.inset)
        }
    }
    
    private func loadAgent(_ agentSummary: SavedAgentSummary) {
        isLoading = true
        errorMessage = nil
        
        do {
            let fullAgent = try storage.loadAgent(id: agentSummary.id)
            try onLoad(fullAgent)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct LoadAgentRow: View {
    let agent: SavedAgentSummary
    let onLoad: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(agent.algorithmType)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    
                    Text("\(agent.episodesTrained) episodes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let successRate = agent.successRate {
                        Text(String(format: "%.0f%% success", successRate * 100))
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(String(format: "Best: %.0f", agent.bestReward))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Button("Load") {
                    onLoad()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Text(agent.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LoadAgentSheet(environmentType: .frozenLake) { _ in }
}


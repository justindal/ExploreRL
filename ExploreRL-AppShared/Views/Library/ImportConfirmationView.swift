//
//  ImportConfirmationView.swift
//

import SwiftUI

struct ImportConfirmationView: View {
    let agents: [SavedAgent]
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAgents: Set<UUID> = []
    @State private var isImporting = false
    @State private var importError: String?
    @State private var importedCount = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if agents.isEmpty {
                    ContentUnavailableView {
                        Label("No Agents Found", systemImage: "tray")
                    } description: {
                        Text("No valid agents were discovered in the selected folder.")
                    }
                } else {
                    List {
                        Section {
                            ForEach(agents) { agent in
                                agentRow(agent)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        toggleSelection(agent.id)
                                    }
                            }
                        } header: {
                            HStack {
                                Text("\(agents.count) agents found")
                                Spacer()
                                Button(selectedAgents.count == agents.count ? "Deselect All" : "Select All") {
                                    if selectedAgents.count == agents.count {
                                        selectedAgents.removeAll()
                                    } else {
                                        selectedAgents = Set(agents.map(\.id))
                                    }
                                }
                                .font(.caption)
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                }
                
                if !agents.isEmpty {
                    VStack(spacing: 12) {
                        if let error = importError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        
                        if isImporting {
                            ProgressView("Importing \(importedCount)/\(selectedAgents.count)...")
                        } else {
                            Button {
                                performImport()
                            } label: {
                                Text("Import \(selectedAgents.count) Agent\(selectedAgents.count == 1 ? "" : "s")")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedAgents.isEmpty)
                        }
                    }
                    .padding()
                    .background(.bar)
                }
            }
            .navigationTitle("Confirm Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete()
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedAgents = Set(agents.map(\.id))
            }
            .interactiveDismissDisabled(isImporting)
        }
    }
    
    @ViewBuilder
    private func agentRow(_ agent: SavedAgent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selectedAgents.contains(agent.id) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectedAgents.contains(agent.id) ? .blue : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Label(agent.environmentType.displayName, systemImage: agent.environmentType.iconName)
                    Text("•")
                    Text(agent.algorithmType)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Text("\(agent.episodesTrained) episodes")
                    Text("Best: \(agent.bestReward, specifier: "%.1f")")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedAgents.contains(id) {
            selectedAgents.remove(id)
        } else {
            selectedAgents.insert(id)
        }
    }
    
    private func performImport() {
        isImporting = true
        importError = nil
        importedCount = 0
        
        let agentsToImport = agents.filter { selectedAgents.contains($0.id) }
        
        Task {
            var successCount = 0
            
            for agent in agentsToImport {
                do {
                    try await SavedAgentsImporter.importAgent(agent)
                    successCount += 1
                    await MainActor.run {
                        importedCount = successCount
                    }
                } catch {
                    await MainActor.run {
                        importError = "Failed to import \(agent.name): \(error.localizedDescription)"
                    }
                }
            }
            
            await MainActor.run {
                isImporting = false
                if successCount > 0 {
                    AgentStorage.shared.loadAgentList()
                    onComplete()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ImportConfirmationView(agents: []) {
        print("Complete")
    }
}


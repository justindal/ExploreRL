//
//  LibraryTabView.swift
//

import SwiftUI

struct LibraryTabView: View {
    @State private var storage = AgentStorage.shared
    @State private var selectedEnvironment: EnvironmentType?
    @State private var agentToRename: SavedAgentSummary?
    @State private var agentToDelete: SavedAgentSummary?
    @State private var newName: String = ""
    @State private var showDeleteConfirmation = false
    
    var filteredAgents: [SavedAgentSummary] {
        if let env = selectedEnvironment {
            return storage.agents(for: env)
        }
        return storage.savedAgents
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if storage.savedAgents.isEmpty {
                    emptyStateView
                } else {
                    agentListView
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: SavedAgentSummary.self) { agent in
                AgentDetailViewiOS(agentSummary: agent)
            }
            .toolbar {
                if !storage.savedAgents.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                selectedEnvironment = nil
                            } label: {
                                HStack {
                                    Text("All")
                                    if selectedEnvironment == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Divider()
                            
                            ForEach(EnvironmentType.allCases, id: \.self) { env in
                                Button {
                                    selectedEnvironment = env
                                } label: {
                                    HStack {
                                        Label(env.displayName, systemImage: env.iconName)
                                        if selectedEnvironment == env {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .refreshable {
                storage.loadAgentList()
            }
        }
        .sheet(item: $agentToRename) { agent in
            RenameAgentSheet(agent: agent, newName: $newName) {
                if !newName.isEmpty {
                    try? storage.renameAgent(id: agent.id, newName: newName)
                }
                agentToRename = nil
                newName = ""
            }
        }
        .alert("Delete Agent?", isPresented: $showDeleteConfirmation, presenting: agentToDelete) { agent in
            Button("Cancel", role: .cancel) {
                agentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                try? storage.deleteAgent(id: agent.id)
                agentToDelete = nil
            }
        } message: { agent in
            Text("Are you sure you want to delete \"\(agent.name)\"? This cannot be undone.")
        }
    }
    
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Saved Agents", systemImage: "tray")
        } description: {
            Text("Train an agent and save it to see it here.")
        }
    }
    
    
    private var agentListView: some View {
        List {
            if filteredAgents.isEmpty {
                ContentUnavailableView {
                    Label("No Agents", systemImage: "tray")
                } description: {
                    Text("No agents match the current filter.")
                }
            } else {
                ForEach(filteredAgents) { agent in
                    NavigationLink(value: agent) {
                        SavedAgentRowCompact(agent: agent)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            agentToDelete = agent
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            newName = agent.name
                            agentToRename = agent
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
    }
}


struct SavedAgentRowCompact: View {
    let agent: SavedAgentSummary
    
    private var environmentColor: Color {
        agent.environmentType == .frozenLake ? .cyan : .orange
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(environmentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: agent.environmentType.iconName)
                    .font(.title3)
                    .foregroundStyle(environmentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                    .lineLimit(1)
                
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
            
            VStack(alignment: .trailing, spacing: 4) {
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
                
                Text(agent.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}


struct AgentDetailViewiOS: View {
    let agentSummary: SavedAgentSummary
    @State private var fullAgent: SavedAgent?
    @State private var isLoading = true
    
    private var environmentColor: Color {
        agentSummary.environmentType == .frozenLake ? .cyan : .orange
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                statsGrid
                
                if let agent = fullAgent {
                    hyperparametersSection(agent: agent)
                    AgentDataVisualizationView(agent: agent)
                } else if isLoading {
                    ProgressView("Loading agent data...")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                timestampsSection
            }
            .padding()
        }
        .navigationTitle(agentSummary.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAgent()
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(environmentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: agentSummary.environmentType.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(environmentColor)
            }
            
            VStack(spacing: 4) {
                Text(agentSummary.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    Text(agentSummary.algorithmType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(6)
                    
                    Text(agentSummary.environmentType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(environmentColor.opacity(0.2))
                        .foregroundStyle(environmentColor)
                        .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
    
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBoxiOS(title: "Episodes", value: "\(agentSummary.episodesTrained)", icon: "number", color: .blue)
            
            if let successRate = agentSummary.successRate {
                StatBoxiOS(title: "Success Rate", value: String(format: "%.0f%%", successRate * 100), icon: "checkmark.circle", color: .green)
            } else {
                StatBoxiOS(title: "Best Reward", value: String(format: "%.0f", agentSummary.bestReward), icon: "star", color: .orange)
            }
            
            StatBoxiOS(title: "Avg Reward", value: String(format: "%.1f", agentSummary.averageReward), icon: "chart.line.uptrend.xyaxis", color: .purple)
            
            StatBoxiOS(title: "File Size", value: agentSummary.formattedFileSize, icon: "doc", color: .gray)
        }
    }
    
    
    private func hyperparametersSection(agent: SavedAgent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hyperparameters")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(Array(agent.hyperparameters.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(formatKey(key))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatValue(agent.hyperparameters[key] ?? 0))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    
    private var timestampsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Created")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(agentSummary.createdAt, style: .date)
            }
            .font(.caption)
            
            HStack {
                Text("Last Updated")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(agentSummary.updatedAt, style: .date)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    
    private func loadAgent() {
        isLoading = true
        let agentId = agentSummary.id
        Task.detached(priority: .userInitiated) {
            let agent = try? await AgentStorage.shared.loadAgent(id: agentId)
            await MainActor.run {
                self.fullAgent = agent
                self.isLoading = false
            }
        }
    }
    
    private func formatKey(_ key: String) -> String {
        var result = ""
        for char in key {
            if char.isUppercase {
                result += " "
            }
            result += String(char)
        }
        return result.prefix(1).uppercased() + result.dropFirst()
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 10000 {
            return String(format: "%.0f", value)
        } else if abs(value) < 0.001 {
            return String(format: "%.6f", value)
        } else if abs(value) < 1 {
            return String(format: "%.4f", value)
        } else {
            return String(format: "%.3f", value)
        }
    }
}


struct StatBoxiOS: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

#Preview {
    LibraryTabView()
}


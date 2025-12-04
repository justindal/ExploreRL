//
//  LibraryContentView.swift
//

import SwiftUI

struct LibraryContentView: View {
    @State private var storage = AgentStorage.shared
    @State private var selectedAgent: SavedAgentSummary?
    @State private var selectedEnvironment: EnvironmentType?
    @State private var agentToRename: SavedAgentSummary?
    @State private var agentToDelete: SavedAgentSummary?
    @State private var newName: String = ""
    @State private var showDeleteConfirmation = false
    @State private var searchText: String = ""
    @State private var sortOption: LibrarySortOption = .dateNewest
    @State private var isSelecting = false
    @State private var selectedAgents: Set<UUID> = []
    @State private var showBatchDeleteConfirmation = false
    @State private var agentToDuplicate: SavedAgentSummary?
    @State private var showDuplicateConfirmation = false
    
    var filteredAgents: [SavedAgentSummary] {
        var agents: [SavedAgentSummary]
        
        if let env = selectedEnvironment {
            agents = storage.agents(for: env)
        } else {
            agents = storage.savedAgents
        }
        
        if !searchText.isEmpty {
            agents = agents.filter { agent in
                agent.name.localizedCaseInsensitiveContains(searchText) ||
                agent.algorithmType.localizedCaseInsensitiveContains(searchText) ||
                agent.environmentType.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch sortOption {
        case .dateNewest:
            agents.sort { $0.updatedAt > $1.updatedAt }
        case .dateOldest:
            agents.sort { $0.updatedAt < $1.updatedAt }
        case .nameAZ:
            agents.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .nameZA:
            agents.sort { $0.name.localizedCompare($1.name) == .orderedDescending }
        case .episodesHigh:
            agents.sort { $0.episodesTrained > $1.episodesTrained }
        case .rewardHigh:
            agents.sort { $0.bestReward > $1.bestReward }
        }
        
        return agents
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    agentListContent
                }
                .frame(width: min(max(geometry.size.width * 0.4, 350), 500))
                .clipped()
                
                Divider()
                
                if let agent = selectedAgent {
                    LibraryAgentDetailView(agentSummary: agent)
                        .frame(maxWidth: .infinity)
                } else {
                    ContentUnavailableView {
                        Label("Select an Agent", systemImage: "tray")
                    } description: {
                        Text("Choose an agent from the list to view its details.")
                    }
                    .frame(maxWidth: .infinity)
                }
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
                if selectedAgent?.id == agent.id {
                    selectedAgent = nil
                }
                try? storage.deleteAgent(id: agent.id)
                agentToDelete = nil
            }
        } message: { agent in
            Text("Are you sure you want to delete \"\(agent.name)\"? This cannot be undone.")
        }
        .alert("Delete \(selectedAgents.count) Agents?", isPresented: $showBatchDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                selectedAgents.removeAll()
            }
            Button("Delete All", role: .destructive) {
                deleteSelectedAgents()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedAgents.count) agents? This cannot be undone.")
        }
        .alert("Duplicate Agent?", isPresented: $showDuplicateConfirmation, presenting: agentToDuplicate) { agent in
            Button("Cancel", role: .cancel) {
                agentToDuplicate = nil
            }
            Button("Duplicate") {
                duplicateAgent(agent)
            }
        } message: { agent in
            Text("Create a copy of \"\(agent.name)\"?")
        }
    }
    
    @ViewBuilder
    private var agentListContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Library")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !storage.savedAgents.isEmpty {
                    Menu {
                        Picker("Filter by Environment", selection: $selectedEnvironment) {
                            Text("All Environments").tag(nil as EnvironmentType?)
                            Divider()
                            ForEach(EnvironmentType.allCases, id: \.self) { env in
                                Label(env.displayName, systemImage: env.iconName)
                                    .tag(env as EnvironmentType?)
                            }
                        }
                        
                        Divider()
                        
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(LibrarySortOption.allCases) { option in
                                Label(option.rawValue, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .menuStyle(.borderlessButton)
                    
                    if isSelecting {
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                if selectedAgents.count == filteredAgents.count {
                                    selectedAgents.removeAll()
                                } else {
                                    selectedAgents = Set(filteredAgents.map(\.id))
                                }
                            }
                        } label: {
                            Text(selectedAgents.count == filteredAgents.count ? "Deselect All" : "Select All")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            withAnimation {
                                isSelecting = false
                                selectedAgents.removeAll()
                            }
                        } label: {
                            Text("Done")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Button {
                            withAnimation {
                                isSelecting = true
                            }
                        } label: {
                            Text("Select")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .padding()
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search agents...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            if storage.savedAgents.isEmpty {
                ContentUnavailableView {
                    Label("No Saved Agents", systemImage: "tray")
                } description: {
                    Text("Train an agent and save it to see it here.")
                }
                .frame(maxHeight: .infinity)
            } else {
                agentListView
            }
        }
    }
    
    private var agentListView: some View {
        List(selection: $selectedAgent) {
            if isSelecting && !selectedAgents.isEmpty {
                HStack {
                    Text("\(selectedAgents.count) selected")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .destructive) {
                        showBatchDeleteConfirmation = true
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .listRowSeparator(.hidden)
            }
            
            if filteredAgents.isEmpty {
                ContentUnavailableView {
                    Label("No Agents", systemImage: "tray")
                } description: {
                    Text("No agents match the current filter.")
                }
            } else {
                ForEach(filteredAgents) { agent in
                    if isSelecting {
                        HStack {
                            Image(systemName: selectedAgents.contains(agent.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedAgents.contains(agent.id) ? .blue : .secondary)
                            LibraryAgentRow(agent: agent)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.15)) {
                                if selectedAgents.contains(agent.id) {
                                    selectedAgents.remove(agent.id)
                                } else {
                                    selectedAgents.insert(agent.id)
                                }
                            }
                        }
                        .listRowBackground(
                            selectedAgents.contains(agent.id)
                            ? Color.accentColor.opacity(0.15)
                            : nil
                        )
                    } else {
                        LibraryAgentRow(agent: agent)
                            .tag(agent)
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
                                
                                Button {
                                    agentToDuplicate = agent
                                    showDuplicateConfirmation = true
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    newName = agent.name
                                    agentToRename = agent
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                
                                Button {
                                    agentToDuplicate = agent
                                    showDuplicateConfirmation = true
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    agentToDelete = agent
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.inset)
    }
    
    private func deleteSelectedAgents() {
        for id in selectedAgents {
            if selectedAgent?.id == id {
                selectedAgent = nil
            }
            try? storage.deleteAgent(id: id)
        }
        selectedAgents.removeAll()
        isSelecting = false
    }
    
    private func duplicateAgent(_ agent: SavedAgentSummary) {
        do {
            try storage.duplicateAgent(id: agent.id)
        } catch {
            print("Failed to duplicate agent: \(error)")
        }
        agentToDuplicate = nil
    }
}


//
//  LibraryStackView.swift
//

import SwiftUI

struct LibraryStackView: View {
    @State private var storage = AgentStorage.shared
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
    @State private var showSettings = false
    
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
        NavigationStack {
            Group {
                if storage.savedAgents.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Agents", systemImage: "tray")
                    } description: {
                        Text("Train an agent and save it to see it here.")
                    }
                } else {
                    agentListView
                }
            }
            .navigationTitle("Library")
            .navigationDestination(isPresented: $showSettings) {
                LibrarySettingsView()
            }
            .navigationDestination(for: SavedAgentSummary.self) { agent in
                LibraryAgentDetailView(agentSummary: agent)
            }
            .searchable(text: $searchText, prompt: "Search agents...")
            .toolbar {
                if !storage.savedAgents.isEmpty {
                    ToolbarItem(placement: .automatic) {
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
                        .padding(.trailing, isSelecting ? 8 : 0)
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        if isSelecting {
                            HStack(spacing: 12) {
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
                                }
                                
                                Button("Done") {
                                    withAnimation {
                                        isSelecting = false
                                        selectedAgents.removeAll()
                                    }
                                }
                                .fontWeight(.semibold)
                            }
                        } else {
                            Button {
                                withAnimation {
                                    isSelecting = true
                                }
                            } label: {
                                Image(systemName: "checkmark.circle")
                            }
                        }
                    }
                }
                
                if !isSelecting {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
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
    
    private var agentListView: some View {
        List {
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
                        NavigationLink(value: agent) {
                            LibraryAgentRow(agent: agent)
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
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
    
    private func deleteSelectedAgents() {
        for id in selectedAgents {
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


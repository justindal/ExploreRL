//
//  SavedAgentsView.swift
//

import SwiftUI
import MLX


enum AgentSortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"
    case episodesHigh = "Most Episodes"
    case rewardHigh = "Best Reward"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dateNewest: return "arrow.down.circle"
        case .dateOldest: return "arrow.up.circle"
        case .nameAZ: return "textformat.abc"
        case .nameZA: return "textformat.abc"
        case .episodesHigh: return "number.circle"
        case .rewardHigh: return "star.circle"
        }
    }
}


struct SavedAgentsView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var storage = AgentStorage.shared
    @State private var selectedEnvironment: EnvironmentType?
    @State private var selectedAgent: SavedAgentSummary?
    @State private var agentToRename: SavedAgentSummary?
    @State private var agentToDelete: SavedAgentSummary?
    @State private var newName: String = ""
    @State private var showDeleteConfirmation = false
    
    @State private var searchText: String = ""
    @State private var sortOption: AgentSortOption = .dateNewest
    @State private var isSelecting: Bool = false
    @State private var selectedAgents: Set<UUID> = [] 
    @State private var singleSelection: UUID? = nil
    @State private var showBatchDeleteConfirmation = false
    @State private var showDuplicateConfirmation = false
    @State private var agentToDuplicate: SavedAgentSummary?
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var filteredAndSortedAgents: [SavedAgentSummary] {
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
        mainContent
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
    
    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        HSplitView {
            listSection
            detailSection
        }
        #else
        if isCompact {
            NavigationStack {
                listSection
                    .navigationTitle("Saved Agents")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(for: SavedAgentSummary.self) { agent in
                        AgentDetailView(agent: agent)
                    }
            }
        } else {
            NavigationStack {
                listSection
                    .navigationDestination(item: $selectedAgent) { agent in
                        AgentDetailView(agent: agent)
                    }
            }
        }
        #endif
    }
    
    private var listSection: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            headerView
            Divider()
            #endif
            
            if filteredAndSortedAgents.isEmpty {
                emptyStateView
            } else {
                agentListView
            }
        }
        #if os(macOS)
        .frame(minWidth: 380)
        #else
        .searchable(text: $searchText, prompt: "Search agents...")
        .toolbar {
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
                        ForEach(AgentSortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.icon)
                                .tag(option)
                        }
                    }
                } label: {
                    Label("Options", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(isSelecting ? "Done" : "Select") {
                    withAnimation {
                        if isSelecting {
                            isSelecting = false
                            selectedAgents.removeAll()
                        } else {
                            isSelecting = true
                        }
                    }
                }
            }
        }
        #endif
    }
    
    #if os(macOS)
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Saved Agents")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isSelecting {
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                if selectedAgents.count == filteredAndSortedAgents.count {
                                    selectedAgents.removeAll()
                                } else {
                                    selectedAgents = Set(filteredAndSortedAgents.map(\.id))
                                }
                            }
                        } label: {
                            Text(selectedAgents.count == filteredAndSortedAgents.count ? "Deselect All" : "Select All")
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Done") {
                            withAnimation {
                                isSelecting = false
                                selectedAgents.removeAll()
                                singleSelection = selectedAgent?.id
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button {
                        withAnimation {
                            isSelecting = true
                            singleSelection = nil
                        }
                    } label: {
                        Label("Select", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .help("Enter selection mode to select multiple agents")
                }
            }
            
            HStack(spacing: 12) {
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
                
                Picker("Environment", selection: $selectedEnvironment) {
                    Text("All").tag(nil as EnvironmentType?)
                    ForEach(EnvironmentType.allCases, id: \.self) { env in
                        Label(env.displayName, systemImage: env.iconName)
                            .tag(env as EnvironmentType?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
                
                Menu {
                    ForEach(AgentSortOption.allCases) { option in
                        Button {
                            sortOption = option
                        } label: {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    Label(sortOption.rawValue, systemImage: "arrow.up.arrow.down")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 140)
            }
            
            if isSelecting && !selectedAgents.isEmpty {
                HStack {
                    Text("\(selectedAgents.count) selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        showBatchDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
    
    private var detailSection: some View {
        Group {
            if let agent = selectedAgent {
                AgentDetailView(agent: agent)
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Select an agent to view details")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(minWidth: 300)
            }
        }
    }
    #endif
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if !searchText.isEmpty {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No Results")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("No agents match \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Clear Search") {
                    searchText = ""
                }
                .buttonStyle(.bordered)
            } else {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No Saved Agents")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("Train an agent and save it to see it here.\nYou can then evaluate it or continue training.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var agentListView: some View {
        #if os(macOS)
        macOSAgentList
        #else
        iOSAgentList
        #endif
    }
    
    #if os(macOS)
    @ViewBuilder
    private var macOSAgentList: some View {
        if isSelecting {
            List {
                ForEach(filteredAndSortedAgents) { agent in
                    HStack(spacing: 12) {
                        Image(systemName: selectedAgents.contains(agent.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedAgents.contains(agent.id) ? Color.accentColor : .secondary)
                            .font(.title3)
                        
                        SavedAgentRow(agent: agent)
                        
                        Spacer()
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
                        : Color.clear
                    )
                    .contextMenu {
                        agentContextMenu(for: agent)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        agentSwipeActions(for: agent)
                    }
                }
            }
            .listStyle(.inset)
        } else {
            List(filteredAndSortedAgents, selection: $singleSelection) { agent in
                SavedAgentRow(agent: agent)
                    .tag(agent.id)
                    .contextMenu {
                        agentContextMenu(for: agent)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        agentSwipeActions(for: agent)
                    }
            }
            .listStyle(.inset)
            .onChange(of: singleSelection) { _, newValue in
                if let id = newValue {
                    selectedAgent = filteredAndSortedAgents.first { $0.id == id }
                } else {
                    selectedAgent = nil
                }
            }
        }
    }
    #endif
    
    #if os(iOS)
    @ViewBuilder
    private var iOSAgentList: some View {
        List {
            ForEach(filteredAndSortedAgents) { agent in
                if isCompact && !isSelecting {
                    NavigationLink(value: agent) {
                        SavedAgentRow(agent: agent)
                    }
                    .contextMenu {
                        agentContextMenu(for: agent)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        agentSwipeActions(for: agent)
                    }
                } else {
                    SavedAgentRow(agent: agent)
                        .tag(agent.id)
                        .onTapGesture {
                            if isSelecting {
                                if selectedAgents.contains(agent.id) {
                                    selectedAgents.remove(agent.id)
                                } else {
                                    selectedAgents.insert(agent.id)
                                }
                            } else {
                                selectedAgent = agent
                            }
                        }
                        .listRowBackground(
                            isSelecting && selectedAgents.contains(agent.id)
                            ? Color.accentColor.opacity(0.15)
                            : nil
                        )
                        .contextMenu {
                            agentContextMenu(for: agent)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            agentSwipeActions(for: agent)
                        }
                }
            }
        }
        .listStyle(.inset)
    }
    #endif
    
    @ViewBuilder
    private func agentContextMenu(for agent: SavedAgentSummary) -> some View {
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
    
    @ViewBuilder
    private func agentSwipeActions(for agent: SavedAgentSummary) -> some View {
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
    
    
    private func deleteSelectedAgents() {
        for agentId in selectedAgents {
            try? storage.deleteAgent(id: agentId)
        }
        selectedAgents.removeAll()
        isSelecting = false
        selectedAgent = nil
        singleSelection = nil
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


struct AgentDetailView: View {
    let agent: SavedAgentSummary
    @State private var fullAgent: SavedAgent?
    @State private var isLoadingDetails = true
    
    private var environmentColor: Color {
        agent.environmentType.accentColor
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(environmentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: agent.environmentType.iconName)
                            .font(.system(size: 36))
                            .foregroundStyle(environmentColor)
                    }
                    
                    Text(agent.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text(agent.environmentType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(environmentColor.opacity(0.15))
                            .foregroundStyle(environmentColor)
                            .cornerRadius(6)
                        
                        Text(agent.algorithmType)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .cornerRadius(6)
                    }
                }
                .padding(.top, 20)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Performance")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DetailMetricCard(
                            title: "Episodes Trained",
                            value: "\(agent.episodesTrained)",
                            icon: "number",
                            color: .purple
                        )
                        
                        DetailMetricCard(
                            title: "Best Reward",
                            value: String(format: "%.1f", agent.bestReward),
                            icon: "star.fill",
                            color: .orange
                        )
                        
                        DetailMetricCard(
                            title: "Avg Reward",
                            value: String(format: "%.2f", agent.averageReward),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                        
                        if let successRate = agent.successRate {
                            DetailMetricCard(
                                title: "Success Rate",
                                value: String(format: "%.0f%%", successRate * 100),
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        } else {
                            DetailMetricCard(
                                title: "File Size",
                                value: agent.formattedFileSize,
                                icon: "doc.fill",
                                color: .gray
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                if let fullAgent = fullAgent {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hyperparameters")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(fullAgent.hyperparameters.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(formatHyperparameterName(key))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(formatHyperparameterValue(fullAgent.hyperparameters[key] ?? 0))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    if !fullAgent.environmentConfig.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Environment Config")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(fullAgent.environmentConfig.keys.sorted()), id: \.self) { key in
                                    HStack {
                                        Text(formatHyperparameterName(key))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(fullAgent.environmentConfig[key] ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    AgentDataVisualizationView(agent: fullAgent)
                        .padding(.horizontal)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Created")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(agent.createdAt, style: .date)
                            .font(.caption)
                        Text(agent.createdAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(agent.updatedAt, style: .date)
                            .font(.caption)
                        Text(agent.updatedAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .frame(minWidth: 300)
        .background(Color.gray.opacity(0.03))
        .onAppear {
            loadFullAgent()
        }
        .onChange(of: agent) { _, _ in
            loadFullAgent()
        }
        #if os(iOS)
        .navigationTitle(agent.name)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func loadFullAgent() {
        isLoadingDetails = true
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                fullAgent = try? AgentStorage.shared.loadAgent(id: agent.id)
                isLoadingDetails = false
            }
        }
    }
    
    private func formatHyperparameterName(_ name: String) -> String {
        var result = ""
        for char in name {
            if char.isUppercase {
                result += " "
            }
            result += String(char)
        }
        return result.prefix(1).uppercased() + result.dropFirst()
    }
    
    private func formatHyperparameterValue(_ value: Double) -> String {
        if value == value.rounded() && Swift.abs(value) < 10000 {
            return String(format: "%.0f", value)
        } else if Swift.abs(value) < 0.001 {
            return String(format: "%.6f", value)
        } else if Swift.abs(value) < 1 {
            return String(format: "%.4f", value)
        } else {
            return String(format: "%.3f", value)
        }
    }
}


struct DetailMetricCard: View {
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

struct SavedAgentRow: View {
    let agent: SavedAgentSummary
    
    private var environmentColor: Color {
        agent.environmentType.accentColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
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
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    
                    Label("\(agent.episodesTrained)", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Label(agent.formattedFileSize, systemImage: "doc.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let successRate = agent.successRate {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text(String(format: "%.0f%%", successRate * 100))
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.green)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text(String(format: "%.0f", agent.bestReward))
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                }
                
                Text(agent.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct RenameAgentSheet: View {
    let agent: SavedAgentSummary
    @Binding var newName: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Agent Name", text: $newName)
                }
                
                Section {
                    HStack {
                        Text("Environment")
                        Spacer()
                        Text(agent.environmentType.displayName)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Algorithm")
                        Spacer()
                        Text(agent.algorithmType)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Episodes Trained")
                        Spacer()
                        Text("\(agent.episodesTrained)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Rename Agent")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 250)
        #endif
    }
}


struct AgentDataVisualizationView: View {
    let agent: SavedAgent
    @State private var qTable: [[Double]]?
    @State private var networkLayers: [NetworkLayerInfo]?
    @State private var weightStats: WeightStatistics?
    @State private var sacNetworks: [String: [NetworkLayerInfo]]?
    @State private var sacWeightStats: [String: WeightStatistics]?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedAction: Int = 0
    @State private var selectedLayerForHistogram: String?
    @State private var selectedSACNetwork: String = "actor"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Agent Data")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            } else if agent.environmentType == .frozenLake {
                qTableVisualization
            } else if agent.environmentType == .mountainCarContinuous {
                sacNetworkVisualization
            } else {
                networkVisualization
            }
        }
        .onAppear {
            loadAgentData()
        }
    }
    
    @ViewBuilder
    private var qTableVisualization: some View {
        if let qTable = qTable {
            VStack(alignment: .leading, spacing: 12) {
                Text("Q-Table Heatmap")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Action:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Action", selection: $selectedAction) {
                        Text("← Left").tag(0)
                        Text("↓ Down").tag(1)
                        Text("→ Right").tag(2)
                        Text("↑ Up").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 250)
                }
                
                let gridSize = Int(sqrt(Double(qTable.count)))
                let values = qTable.map { $0[selectedAction] }
                let maxVal = values.max() ?? 1
                let minVal = values.min() ?? 0
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: gridSize), spacing: 2) {
                    ForEach(0..<qTable.count, id: \.self) { state in
                        let value = qTable[state][selectedAction]
                        let normalized = maxVal != minVal ? (value - minVal) / (maxVal - minVal) : 0.5
                        
                        ZStack {
                            Rectangle()
                                .fill(qValueColor(normalized: normalized))
                            
                            Text(String(format: "%.2f", value))
                                .font(.system(size: 8))
                                .foregroundStyle(normalized > 0.5 ? .white : .black)
                        }
                        .frame(height: 30)
                        .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text("Low")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    LinearGradient(
                        colors: [.blue, .green, .yellow, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .cornerRadius(4)
                    
                    Text("High")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("States")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(qTable.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Actions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(qTable.first?.count ?? 0)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Q-Value")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.3f", maxVal))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        } else if !isLoading {
            Text("Unable to load Q-table data")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
    }
    
    @ViewBuilder
    private var networkVisualization: some View {
        if let layers = networkLayers {
            VStack(alignment: .leading, spacing: 16) {
                Text("Neural Network Architecture")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(alignment: .center, spacing: 8) {
                    ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(layerColor(for: layer.type))
                                .frame(width: 60, height: CGFloat(min(100, max(30, layer.outputSize / 2))))
                                .overlay(
                                    VStack(spacing: 2) {
                                        Text("\(layer.outputSize)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                )
                            
                            Text(layer.name)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        if index < layers.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Layer Details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(layers, id: \.name) { layer in
                        HStack {
                            Circle()
                                .fill(layerColor(for: layer.type))
                                .frame(width: 8, height: 8)
                            
                            Text(layer.name)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(layer.inputSize) → \(layer.outputSize)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("(\(layer.paramCount) params)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                if let stats = weightStats {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight Statistics")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            WeightStatCard(title: "Mean", value: String(format: "%.4f", stats.mean))
                            WeightStatCard(title: "Std Dev", value: String(format: "%.4f", stats.stdDev))
                            WeightStatCard(title: "Min", value: String(format: "%.4f", stats.min))
                            WeightStatCard(title: "Max", value: String(format: "%.4f", stats.max))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight Distribution")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            WeightHistogramView(histogram: stats.histogram)
                                .frame(height: 50)
                        }
                        .padding(.top, 4)
                    }
                }
                
                let totalParams = layers.reduce(0) { $0 + $1.paramCount }
                HStack {
                    Text("Total Parameters:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(totalParams)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        } else if !isLoading {
            Text("Unable to load network data")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
    }
    
    @ViewBuilder
    private var sacNetworkVisualization: some View {
        if let networks = sacNetworks {
            VStack(alignment: .leading, spacing: 16) {
                Text("SAC Neural Networks")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                let availableNetworks = Array(networks.keys).sorted()
                Picker("Network", selection: $selectedSACNetwork) {
                    ForEach(availableNetworks, id: \.self) { networkName in
                        Text(networkDisplayName(networkName)).tag(networkName)
                    }
                }
                .pickerStyle(.segmented)
                .onAppear {
                    if !availableNetworks.contains(selectedSACNetwork), let first = availableNetworks.first {
                        selectedSACNetwork = first
                    }
                }
                
                if let layers = networks[selectedSACNetwork] {
                    HStack(alignment: .center, spacing: 8) {
                        ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(layerColor(for: layer.type))
                                    .frame(width: 60, height: CGFloat(min(100, max(30, layer.outputSize / 2))))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Text("\(layer.outputSize)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    )
                                
                                Text(layer.name)
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            if index < layers.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Layer Details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(layers, id: \.name) { layer in
                            HStack {
                                Circle()
                                    .fill(layerColor(for: layer.type))
                                    .frame(width: 8, height: 8)
                                
                                Text(layer.name)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(layer.inputSize) → \(layer.outputSize)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("(\(layer.paramCount) params)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    
                    let totalParams = layers.reduce(0) { $0 + $1.paramCount }
                    HStack {
                        Text("Total Parameters:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(totalParams)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 4)
                }
                
                if let stats = sacWeightStats?[selectedSACNetwork] {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight Statistics (\(selectedSACNetwork))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            WeightStatCard(title: "Mean", value: String(format: "%.4f", stats.mean))
                            WeightStatCard(title: "Std Dev", value: String(format: "%.4f", stats.stdDev))
                            WeightStatCard(title: "Min", value: String(format: "%.4f", stats.min))
                            WeightStatCard(title: "Max", value: String(format: "%.4f", stats.max))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight Distribution")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            WeightHistogramView(histogram: stats.histogram)
                                .frame(height: 50)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        } else if !isLoading {
            Text("Unable to load SAC network data")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
    }
    
    private func networkDisplayName(_ name: String) -> String {
        switch name {
        case "actor": return "Actor"
        case "qf1": return "Q-Function 1"
        case "qf2": return "Q-Function 2"
        case "qEnsemble": return "Q-Ensemble"
        default: return name.capitalized
        }
    }
    
    private func qValueColor(normalized: Double) -> Color {
        if normalized < 0.25 {
            return Color.blue.opacity(0.3 + normalized * 2)
        } else if normalized < 0.5 {
            return Color.green.opacity(0.5 + (normalized - 0.25) * 2)
        } else if normalized < 0.75 {
            return Color.yellow.opacity(0.5 + (normalized - 0.5) * 2)
        } else {
            return Color.red.opacity(0.7 + (normalized - 0.75))
        }
    }
    
    private func layerColor(for type: String) -> Color {
        switch type {
        case "input": return .blue
        case "hidden": return .purple
        case "output": return .green
        default: return .gray
        }
    }
    
    private func loadAgentData() {
        isLoading = true
        errorMessage = nil
        
        let agentCopy = agent
        
        Task.detached(priority: .userInitiated) {
            do {
                if agentCopy.environmentType == .frozenLake {
                    let qTableArray = try await AgentStorage.shared.loadQTable(for: agentCopy)
                    let shape = qTableArray.shape
                    let numStates = shape[0]
                    let numActions = shape[1]
                    
                    var result: [[Double]] = []
                    for s in 0..<numStates {
                        var row: [Double] = []
                        for a in 0..<numActions {
                            let value = qTableArray[s, a].item(Float.self)
                            row.append(Double(value))
                        }
                        result.append(row)
                    }
                    
                    let finalResult = result
                    await MainActor.run {
                        self.qTable = finalResult
                        self.isLoading = false
                    }
                } else if agentCopy.environmentType == .mountainCarContinuous {
                    var allWeights: [String: [String: MLXArray]]
                    var isVmapFormat = false
                    
                    if agentCopy.algorithmType == "SAC-Vmap" || agentCopy.agentDataPath.contains("vmap") {
                        allWeights = try await AgentStorage.shared.loadSACVmapWeights(for: agentCopy)
                        isVmapFormat = true
                    } else {
                        allWeights = try await AgentStorage.shared.loadSACWeights(for: agentCopy)
                    }
                    
                    var networks: [String: [NetworkLayerInfo]] = [:]
                    var weightStats: [String: WeightStatistics] = [:]
                    
                    for (networkName, weights) in allWeights {
                        var layers: [NetworkLayerInfo] = []
                        
                        let inputSize: Int
                        if networkName == "actor" {
                            inputSize = 2
                        } else if networkName == "qEnsemble" || networkName == "qf1" || networkName == "qf2" {
                            inputSize = 3
                        } else {
                            inputSize = 2
                        }
                        
                        layers.append(NetworkLayerInfo(
                            name: "Input",
                            type: "input",
                            inputSize: inputSize,
                            outputSize: inputSize,
                            paramCount: 0
                        ))
                        
                        let sortedKeys = weights.keys.sorted()
                        var layerIndex = 0
                        
                        for key in sortedKeys {
                            if key.contains("weight") {
                                let shape = weights[key]?.shape ?? []
                                if shape.count >= 2 {
                                    let inSize: Int
                                    let outSize: Int
                                    let ensembleSize: Int
                                    
                                    if shape.count == 3 && isVmapFormat && networkName == "qEnsemble" {
                                        ensembleSize = shape[0]
                                        outSize = shape[1]
                                        inSize = shape[2]
                                    } else {
                                        ensembleSize = 1
                                        outSize = shape[0]
                                        inSize = shape[1]
                                    }
                                    
                                    let biasKey = key.replacingOccurrences(of: "weight", with: "bias")
                                    let biasParams = weights[biasKey]?.shape.last ?? 0
                                    let weightParams = inSize * outSize * ensembleSize
                                    
                                    let layerType = layerIndex == sortedKeys.filter { $0.contains("weight") }.count - 1 ? "output" : "hidden"
                                    
                                    let layerName = networkName == "qEnsemble"
                                        ? "Layer \(layerIndex + 1) (x\(ensembleSize))"
                                        : "Layer \(layerIndex + 1)"
                                    
                                    layers.append(NetworkLayerInfo(
                                        name: layerName,
                                        type: layerType,
                                        inputSize: inSize,
                                        outputSize: outSize,
                                        paramCount: weightParams + (biasParams * ensembleSize)
                                    ))
                                    layerIndex += 1
                                }
                            }
                        }
                        
                        networks[networkName] = layers
                        weightStats[networkName] = self.computeWeightStatisticsBackground(weights: weights)
                    }
                    
                    let finalNetworks = networks
                    let finalStats = weightStats
                    await MainActor.run {
                        self.sacNetworks = finalNetworks
                        self.sacWeightStats = finalStats
                        self.isLoading = false
                    }
                } else {
                    let weights = try await AgentStorage.shared.loadNetworkWeights(for: agentCopy)
                    
                    var layers: [NetworkLayerInfo] = []
                    
                    let inputSize = agentCopy.environmentType == .cartPole ? 4 : 2
                    layers.append(NetworkLayerInfo(
                        name: "Input",
                        type: "input",
                        inputSize: inputSize,
                        outputSize: inputSize,
                        paramCount: 0
                    ))
                    
                    let sortedKeys = weights.keys.sorted()
                    var layerIndex = 0
                    
                    for key in sortedKeys {
                        if key.contains("weight") {
                            let shape = weights[key]?.shape ?? []
                            if shape.count >= 2 {
                                let inSize = shape[1]
                                let outSize = shape[0]
                                let biasKey = key.replacingOccurrences(of: "weight", with: "bias")
                                let biasParams = weights[biasKey]?.shape.first ?? 0
                                let weightParams = inSize * outSize
                                
                                let layerType = layerIndex == sortedKeys.filter { $0.contains("weight") }.count - 1 ? "output" : "hidden"
                                
                                layers.append(NetworkLayerInfo(
                                    name: "Layer \(layerIndex + 1)",
                                    type: layerType,
                                    inputSize: inSize,
                                    outputSize: outSize,
                                    paramCount: weightParams + biasParams
                                ))
                                layerIndex += 1
                            }
                        }
                    }
                    
                    let stats = self.computeWeightStatisticsBackground(weights: weights)
                    
                    let finalLayers = layers
                    await MainActor.run {
                        self.networkLayers = finalLayers
                        self.weightStats = stats
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private nonisolated func computeWeightStatisticsBackground(weights: [String: MLXArray]) -> WeightStatistics {
        var allValues: [Float] = []
        var layerStats: [String: LayerStatistics] = [:]
        
        for (key, array) in weights {
            let flattened = array.reshaped([-1])
            let count = flattened.shape[0]
            var layerValues: [Float] = []
            
            for i in 0..<count {
                let value = flattened[i].item(Float.self)
                allValues.append(value)
                layerValues.append(value)
            }
            
            if !layerValues.isEmpty {
                let mean = layerValues.reduce(0, +) / Float(layerValues.count)
                let variance = layerValues.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(layerValues.count)
                let stdDev = sqrt(variance)
                let minVal = layerValues.min() ?? 0
                let maxVal = layerValues.max() ?? 0
                
                layerStats[key] = LayerStatistics(
                    mean: Double(mean),
                    stdDev: Double(stdDev),
                    min: Double(minVal),
                    max: Double(maxVal),
                    count: layerValues.count
                )
            }
        }
        
        guard !allValues.isEmpty else {
            return WeightStatistics(
                mean: 0,
                stdDev: 0,
                min: 0,
                max: 0,
                histogram: Array(repeating: 0, count: 20),
                layerStats: [:]
            )
        }
        
        let mean = allValues.reduce(0, +) / Float(allValues.count)
        let variance = allValues.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(allValues.count)
        let stdDev = sqrt(variance)
        let minVal = allValues.min() ?? 0
        let maxVal = allValues.max() ?? 0
        
        let binCount = 20
        let range = maxVal - minVal
        
        var histogram = Array(repeating: 0, count: binCount)
        if range > 0 {
            let binWidth = range / Float(binCount)
            for value in allValues {
                var binIndex = Int((value - minVal) / binWidth)
                binIndex = max(0, min(binCount - 1, binIndex))
                histogram[binIndex] += 1
            }
        } else {
            histogram[0] = allValues.count
        }
        
        return WeightStatistics(
            mean: Double(mean),
            stdDev: Double(stdDev),
            min: Double(minVal),
            max: Double(maxVal),
            histogram: histogram,
            layerStats: layerStats
        )
    }
}


struct NetworkLayerInfo: Hashable {
    let name: String
    let type: String
    let inputSize: Int
    let outputSize: Int
    let paramCount: Int
}

struct WeightStatistics {
    let mean: Double
    let stdDev: Double
    let min: Double
    let max: Double
    let histogram: [Int]
    let layerStats: [String: LayerStatistics]
}

struct LayerStatistics {
    let mean: Double
    let stdDev: Double
    let min: Double
    let max: Double
    let count: Int
}

struct WeightStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

struct WeightHistogramView: View {
    let histogram: [Int]
    
    var body: some View {
        GeometryReader { geometry in
            let maxCount = histogram.max() ?? 1
            let barWidth = geometry.size.width / CGFloat(histogram.count)
            
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(Array(histogram.enumerated()), id: \.offset) { index, count in
                    let height = maxCount > 0 ? (CGFloat(count) / CGFloat(maxCount)) * geometry.size.height : 0
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.8)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: max(2, barWidth - 1), height: max(1, height))
                }
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
    }
}

#Preview {
    SavedAgentsView()
}

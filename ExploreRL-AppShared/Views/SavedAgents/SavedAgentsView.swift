//
//  SavedAgentsView.swift
//

import SwiftUI
import MLX

struct SavedAgentsView: View {
    @State private var storage = AgentStorage.shared
    @State private var selectedEnvironment: SavedAgent.EnvironmentType?
    @State private var selectedAgent: SavedAgentSummary?
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
    }
    
    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        HSplitView {
            listSection
            detailSection
        }
        #else
        NavigationStack {
            listSection
                .navigationDestination(item: $selectedAgent) { agent in
                    AgentDetailView(agent: agent)
                }
        }
        #endif
    }
    
    private var listSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Saved Agents")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Filter", selection: $selectedEnvironment) {
                    Text("All").tag(nil as SavedAgent.EnvironmentType?)
                    ForEach(SavedAgent.EnvironmentType.allCases, id: \.self) { env in
                        Label(env.displayName, systemImage: env.iconName)
                            .tag(env as SavedAgent.EnvironmentType?)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            
            Divider()
            
            if filteredAgents.isEmpty {
                emptyStateView
            } else {
                agentListView
            }
        }
        #if os(macOS)
        .frame(minWidth: 350)
        #endif
    }
    
    #if os(macOS)
    private var detailSection: some View {
        Group {
            if let agent = selectedAgent {
                AgentDetailView(agent: agent)
            } else {
                VStack {
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
            
            Spacer()
        }
        .padding()
    }
    
    private var agentListView: some View {
        List(selection: $selectedAgent) {
            ForEach(filteredAgents) { agent in
                SavedAgentRow(agent: agent)
                    .tag(agent)
                    .contextMenu {
                        Button {
                            newName = agent.name
                            agentToRename = agent
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            agentToDelete = agent
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
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
        .listStyle(.inset)
    }
}

struct AgentDetailView: View {
    let agent: SavedAgentSummary
    @State private var fullAgent: SavedAgent?
    
    private var environmentColor: Color {
        agent.environmentType == .frozenLake ? .cyan : .orange
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
    }
    
    private func loadFullAgent() {
        fullAgent = try? AgentStorage.shared.loadAgent(id: agent.id)
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
        agent.environmentType == .frozenLake ? .cyan : .orange
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
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedAction: Int = 0
    @State private var selectedLayerForHistogram: String?
    
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
                        
                        if !stats.layerStats.isEmpty {
                            Divider()
                            
                            Text("Per-Layer Statistics")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            ForEach(Array(stats.layerStats.keys.sorted()), id: \.self) { layerName in
                                if let layerStat = stats.layerStats[layerName] {
                                    DisclosureGroup {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading) {
                                                Text("Mean")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                                Text(String(format: "%.4f", layerStat.mean))
                                                    .font(.caption)
                                                    .monospacedDigit()
                                            }
                                            VStack(alignment: .leading) {
                                                Text("Std")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                                Text(String(format: "%.4f", layerStat.stdDev))
                                                    .font(.caption)
                                                    .monospacedDigit()
                                            }
                                            VStack(alignment: .leading) {
                                                Text("Range")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                                Text("[\(String(format: "%.2f", layerStat.min)), \(String(format: "%.2f", layerStat.max))]")
                                                    .font(.caption)
                                                    .monospacedDigit()
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    } label: {
                                        Text(layerName)
                                            .font(.caption)
                                    }
                                }
                            }
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
        
        Task {
            do {
                if agent.environmentType == .frozenLake {
                    let qTableArray = try AgentStorage.shared.loadQTable(for: agent)
                    let shape = qTableArray.shape
                    let numStates = shape[0]
                    let numActions = shape[1]
                    
                    var table: [[Double]] = []
                    for s in 0..<numStates {
                        var row: [Double] = []
                        for a in 0..<numActions {
                            let value = qTableArray[s, a].item(Float.self)
                            row.append(Double(value))
                        }
                        table.append(row)
                    }
                    
                    await MainActor.run {
                        self.qTable = table
                        self.isLoading = false
                    }
                } else {
                    let weights = try AgentStorage.shared.loadNetworkWeights(for: agent)
                    var layers: [NetworkLayerInfo] = []
                    
                    // Input layer
                    layers.append(NetworkLayerInfo(
                        name: "Input",
                        type: "input",
                        inputSize: 4,
                        outputSize: 4,
                        paramCount: 0
                    ))
                    
                    // Find layer weights and extract dimensions
                    let sortedKeys = weights.keys.sorted()
                    var layerIndex = 0
                    
                    for key in sortedKeys {
                        if key.contains("weight") {
                            let shape = weights[key]?.shape ?? []
                            if shape.count >= 2 {
                                let inputSize = shape[1]
                                let outputSize = shape[0]
                                let biasKey = key.replacingOccurrences(of: "weight", with: "bias")
                                let biasParams = weights[biasKey]?.shape.first ?? 0
                                let weightParams = inputSize * outputSize
                                
                                let layerType = layerIndex == sortedKeys.filter { $0.contains("weight") }.count - 1 ? "output" : "hidden"
                                
                                layers.append(NetworkLayerInfo(
                                    name: "Layer \(layerIndex + 1)",
                                    type: layerType,
                                    inputSize: inputSize,
                                    outputSize: outputSize,
                                    paramCount: weightParams + biasParams
                                ))
                                layerIndex += 1
                            }
                        }
                    }
                    
                    let stats = computeWeightStatistics(weights: weights)
                    
                    await MainActor.run {
                        self.networkLayers = layers
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
    
    private func computeWeightStatistics(weights: [String: MLXArray]) -> WeightStatistics {
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
                let variance = layerValues.map { pow($0 - mean, 2) }.reduce(0, +) / Float(layerValues.count)
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
        
        let mean = allValues.isEmpty ? 0 : allValues.reduce(0, +) / Float(allValues.count)
        let variance = allValues.isEmpty ? 0 : allValues.map { pow($0 - mean, 2) }.reduce(0, +) / Float(allValues.count)
        let stdDev = sqrt(variance)
        let minVal = allValues.min() ?? 0
        let maxVal = allValues.max() ?? 0
        
        let histogram = computeHistogram(values: allValues, bins: 20)
        
        return WeightStatistics(
            mean: Double(mean),
            stdDev: Double(stdDev),
            min: Double(minVal),
            max: Double(maxVal),
            histogram: histogram,
            layerStats: layerStats
        )
    }
    
    private func computeHistogram(values: [Float], bins: Int) -> [Int] {
        guard !values.isEmpty else { return Array(repeating: 0, count: bins) }
        
        let minVal = values.min()!
        let maxVal = values.max()!
        let range = maxVal - minVal
        
        guard range > 0 else { return Array(repeating: values.count, count: 1) + Array(repeating: 0, count: bins - 1) }
        
        var histogram = Array(repeating: 0, count: bins)
        let binWidth = range / Float(bins)
        
        for value in values {
            var binIndex = Int((value - minVal) / binWidth)
            binIndex = min(binIndex, bins - 1)
            histogram[binIndex] += 1
        }
        
        return histogram
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


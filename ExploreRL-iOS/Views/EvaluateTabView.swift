//
//  EvaluateTabView.swift
//

import SwiftUI
import Gymnazo

struct EvaluateTabView: View {
    @State private var runner = EvaluationRunner()
    @State private var showLoadSheet = false
    @State private var selectedEnvironment: EnvironmentType?
    @State private var sheetEnvironment: EnvironmentType?
    @State private var isShowingEvaluation = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isShowingEvaluation && runner.loadedAgent != nil {
                    EvaluationContentViewiOS(runner: runner) {
                        // Go back to selection
                        runner.reset()
                        isShowingEvaluation = false
                    }
                } else {
                    environmentSelectionView
                        .navigationTitle("Evaluate")
                }
            }
        }
        .sheet(isPresented: $showLoadSheet, onDismiss: {
            sheetEnvironment = nil
        }) {
            if let env = sheetEnvironment {
                LoadAgentSheetiOS(environmentType: env) { agent in
                    try runner.loadAgent(agent)
                    isShowingEvaluation = true
                }
            }
        }
        .onChange(of: selectedEnvironment) { _, newValue in
            if let env = newValue {
                sheetEnvironment = env
                showLoadSheet = true
                selectedEnvironment = nil
            }
        }
    }
    
    private var environmentSelectionView: some View {
        List {
            Section("Select Environment") {
                ForEach(EnvironmentType.allCases, id: \.self) { env in
                    Button {
                        selectedEnvironment = env
                    } label: {
                        EvaluateEnvironmentRow(environmentType: env)
                    }
                }
            }
        }
    }
}


struct EvaluateEnvironmentRow: View {
    let environmentType: EnvironmentType
    
    private var color: Color {
        environmentType == .frozenLake ? .cyan : .orange
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: environmentType.iconName)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(environmentType.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Load a saved \(environmentType.displayName) agent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}


struct LoadAgentSheetiOS: View {
    let environmentType: EnvironmentType
    let onLoad: (SavedAgent) throws -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var storage = AgentStorage.shared
    @State private var isLoading = false
    @State private var isLoadingList = true
    @State private var errorMessage: String?
    @State private var agents: [SavedAgentSummary] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoadingList {
                    loadingView
                } else if agents.isEmpty {
                    emptyStateView
                } else {
                    agentListView
                }
            }
            .navigationTitle("Load \(environmentType.displayName) Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadAgents()
            }
        }
    }
    
    private func loadAgents() async {
        isLoadingList = true
        storage.loadAgentList()
        try? await Task.sleep(nanoseconds: 150_000_000)
        agents = storage.agents(for: environmentType)
        isLoadingList = false
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading agents...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Saved Agents", systemImage: "tray")
        } description: {
            Text("You haven't saved any \(environmentType.displayName) agents yet.\n\nGo to the Train tab to train an agent, then save it to evaluate later.")
        } actions: {
            Button("Go to Train") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var agentListView: some View {
        List {
            if let error = errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(error)
                            .font(.subheadline)
                    }
                }
            }
            
            Section("\(agents.count) agent\(agents.count == 1 ? "" : "s")") {
                ForEach(agents) { agent in
                    Button {
                        loadAgent(agent)
                    } label: {
                        LoadAgentRowView(agent: agent, isLoading: isLoading)
                    }
                    .disabled(isLoading)
                }
            }
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

struct LoadAgentRowView: View {
    let agent: SavedAgentSummary
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
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
            
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}


struct EvaluationContentViewiOS: View {
    @Bindable var runner: EvaluationRunner
    let onBack: () -> Void
    @State private var showResults = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                agentInfoHeader
                visualizationSection
                statsSection
                controlsSection
                settingsSection
            }
            .padding()
        }
        .navigationTitle("Evaluation")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    runner.stopEvaluation()
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .sheet(isPresented: $showResults) {
            EvaluationResultsSheetiOS(runner: runner)
        }
    }
    
    
    @ViewBuilder
    private var agentInfoHeader: some View {
        if let agent = runner.loadedAgent {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(agent.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 8) {
                            Text(agent.algorithmType)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .cornerRadius(4)
                            
                            Text("\(agent.episodesTrained) episodes trained")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
    }
    
    
    @ViewBuilder
    private var visualizationSection: some View {
        Group {
            if let agent = runner.loadedAgent {
                switch agent.environmentType {
                case .frozenLake:
                    if let snapshot = runner.frozenLakeSnapshot {
                        FrozenLakeCanvasView(snapshot: snapshot)
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(12)
                            .overlay {
                                if let policy = runner.frozenLakePolicy {
                                    PolicyOverlayView(map: runner.frozenLakeMap, policy: policy)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                case .cartPole:
                    if let snapshot = runner.cartPoleSnapshot {
                        CartPoleViewAdapter(snapshot: snapshot)
                            .aspectRatio(1.5, contentMode: .fit)
                            .cornerRadius(12)
                    }
                case .mountainCar:
                    if let snapshot = runner.mountainCarSnapshot {
                        MountainCarCanvasView(snapshot: snapshot)
                            .aspectRatio(2.0, contentMode: .fit)
                            .cornerRadius(12)
                    }
                case .mountainCarContinuous:
                    if let snapshot = runner.mountainCarContinuousSnapshot {
                        MountainCarCanvasView(snapshot: snapshot)
                            .aspectRatio(2.0, contentMode: .fit)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                EvalStatCardiOS(
                    title: "Episode",
                    value: "\(runner.currentEpisode)/\(runner.episodesToRun)",
                    color: .blue
                )
                EvalStatCardiOS(
                    title: "Step",
                    value: "\(runner.currentStep)",
                    color: .purple
                )
                EvalStatCardiOS(
                    title: "Reward",
                    value: String(format: "%.0f", runner.episodeReward),
                    color: .cyan
                )
            }
            
            HStack(spacing: 12) {
                EvalStatCardiOS(
                    title: "Avg Reward",
                    value: String(format: "%.1f", runner.averageReward),
                    color: .green
                )
                if runner.loadedAgent?.environmentType == .frozenLake {
                    EvalStatCardiOS(
                        title: "Success",
                        value: String(format: "%.0f%%", runner.successRate * 100),
                        color: .orange
                    )
                } else {
                    EvalStatCardiOS(
                        title: "Avg Steps",
                        value: String(format: "%.0f", runner.averageSteps),
                        color: .orange
                    )
                }
            }
        }
    }
    
    
    private var controlsSection: some View {
        HStack(spacing: 16) {
            Button {
                if runner.isRunning {
                    runner.stopEvaluation()
                } else {
                    runner.startEvaluation()
                }
            } label: {
                Label(
                    runner.isRunning ? "Stop" : "Start Evaluation",
                    systemImage: runner.isRunning ? "stop.fill" : "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(runner.isRunning ? .red : .green)
            
            if !runner.episodeRewards.isEmpty {
                Button {
                    showResults = true
                } label: {
                    Label("Results", systemImage: "chart.bar")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
            
            HStack {
                Text("Episodes")
                Spacer()
                Stepper("\(runner.episodesToRun)", value: $runner.episodesToRun, in: 10...1000, step: 10)
                    .labelsHidden()
                Text("\(runner.episodesToRun)")
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }
            .disabled(runner.isRunning)
            
            HStack {
                Text("FPS")
                Spacer()
                Slider(value: $runner.targetFPS, in: 1...60, step: 1)
                    .frame(width: 150)
                Text("\(Int(runner.targetFPS))")
                    .monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }
            
            Toggle("Show Visualization", isOn: $runner.showVisualization)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}


struct EvalStatCardiOS: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}


struct EvaluationResultsSheetiOS: View {
    let runner: EvaluationRunner
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Episodes Run", value: "\(runner.currentEpisode)")
                    LabeledContent("Average Reward", value: String(format: "%.2f", runner.averageReward))
                    LabeledContent("Total Reward", value: String(format: "%.2f", runner.totalReward))
                    if runner.loadedAgent?.environmentType == .frozenLake {
                        LabeledContent("Success Rate", value: String(format: "%.1f%%", runner.successRate * 100))
                        LabeledContent("Successes", value: "\(runner.successCount)")
                    }
                    LabeledContent("Average Steps", value: String(format: "%.1f", runner.averageSteps))
                }
                
                if !runner.episodeRewards.isEmpty {
                    Section("Rewards") {
                        ForEach(Array(runner.episodeRewards.enumerated()), id: \.offset) { index, reward in
                            LabeledContent("Episode \(index + 1)", value: String(format: "%.1f", reward))
                        }
                    }
                }
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EvaluateTabView()
}

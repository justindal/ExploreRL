//
//  EvaluationView.swift
//

import SwiftUI
import Gymnazo

struct EvaluationView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var runner = EvaluationRunner()
    @State private var showLoadSheet = false
    @State private var selectedEnvironment: EnvironmentType = .frozenLake
    @State private var showResults = false
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            if runner.loadedAgent == nil {
                noAgentView
            } else {
                evaluationContentView
            }
        }
        .sheet(isPresented: $showLoadSheet) {
            LoadAgentSheet(environmentType: selectedEnvironment) { agent in
                try runner.loadAgent(agent)
            }
        }
        .sheet(isPresented: $showResults) {
            resultsSheet
        }
        .onDisappear {
            runner.reset()
        }
    }
    
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Evaluation Mode")
                    .font(isCompact ? .headline : .title2)
                    .fontWeight(.semibold)
                
                if let agent = runner.loadedAgent {
                    Text(agent.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if runner.loadedAgent != nil {
                Button {
                    showLoadSheet = true
                } label: {
                    if isCompact {
                        Label("Load Different", systemImage: "tray.and.arrow.down")
                            .labelStyle(.iconOnly)
                    } else {
                        Label("Load Different", systemImage: "tray.and.arrow.down")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    
    private var noAgentView: some View {
        ScrollView {
            VStack(spacing: isCompact ? 24 : 32) {
                Spacer(minLength: isCompact ? 20 : 40)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isCompact ? 80 : 120, height: isCompact ? 80 : 120)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: isCompact ? 32 : 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Evaluation Mode")
                        .font(isCompact ? .title2 : .largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Test your trained agents without further training.")
                        .font(isCompact ? .subheadline : .body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                
                VStack(spacing: 12) {
                    Text("Select Environment")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    if isCompact {
                        VStack(spacing: 12) {
                            ForEach(EnvironmentType.allCases, id: \.self) { type in
                                compactEnvironmentCard(type: type)
                            }
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                            ForEach(EnvironmentType.allCases, id: \.self) { type in
                                EvalEnvironmentCard(
                                    type: type,
                                    isSelected: selectedEnvironment == type
                                ) {
                                    selectedEnvironment = type
                                }
                            }
                        }
                        .frame(maxWidth: 600)
                    }
                }
                
                Button {
                    showLoadSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Load Agent")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: isCompact ? 160 : 200, height: isCompact ? 44 : 50)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 20)
                
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Train an agent first, then save it to evaluate here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .padding()
        }
    }
    
    
    private func compactEnvironmentCard(type: EnvironmentType) -> some View {
        let isSelected = selectedEnvironment == type
        let color = type.accentColor
        
        return Button {
            selectedEnvironment = type
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: type.iconName)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(type.defaultAlgorithm)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(color)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    
    private var evaluationContentView: some View {
        Group {
            if isCompact {
                ScrollView {
                    VStack(spacing: 16) {
                        compactStatsView
                        visualizationView
                        controlsView
                        
                        if !runner.episodeRewards.isEmpty {
                            compactResultsSummary
                        }
                    }
                    .padding()
                }
            } else {
                HStack(spacing: 0) {
                    VStack(spacing: 20) {
                        statsBar
                        visualizationView
                        controlsView
                        Spacer()
                    }
                    .padding()
                    .frame(minWidth: 400)
                    
                    resultsSidebar
                }
            }
        }
    }
    
    
    private var compactStatsView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            compactStatCard(title: "Episode", value: "\(runner.currentEpisode)/\(runner.episodesToRun)", icon: "number")
            compactStatCard(title: "Step", value: "\(runner.currentStep)", icon: "figure.walk")
            compactStatCard(title: "Reward", value: String(format: "%.1f", runner.episodeReward), icon: "star.fill")
            
            if runner.loadedAgent?.environmentType == .frozenLake {
                compactStatCard(title: "Success", value: String(format: "%.0f%%", runner.successRate * 100), icon: "checkmark.circle.fill", color: .green)
            } else {
                compactStatCard(title: "Avg Reward", value: String(format: "%.1f", runner.averageReward), icon: "chart.line.uptrend.xyaxis", color: .orange)
            }
        }
    }
    
    private func compactStatCard(title: String, value: String, icon: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    
    private var statsBar: some View {
        HStack(spacing: 24) {
            EvalStatItem(title: "Episode", value: "\(runner.currentEpisode) / \(runner.episodesToRun)", icon: "number")
            EvalStatItem(title: "Step", value: "\(runner.currentStep)", icon: "figure.walk")
            EvalStatItem(title: "Reward", value: String(format: "%.1f", runner.episodeReward), icon: "star.fill")
            
            if runner.loadedAgent?.environmentType == .frozenLake {
                EvalStatItem(title: "Success Rate", value: String(format: "%.0f%%", runner.successRate * 100), icon: "checkmark.circle.fill", color: .green)
            } else {
                EvalStatItem(title: "Avg Reward", value: String(format: "%.1f", runner.averageReward), icon: "chart.line.uptrend.xyaxis", color: .orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    
    @ViewBuilder
    private var visualizationView: some View {
        if let agent = runner.loadedAgent {
            switch agent.environmentType {
            case .frozenLake:
                if let snapshot = runner.frozenLakeSnapshot {
                    FrozenLakeCanvasView(snapshot: snapshot)
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: isCompact ? .infinity : 400, maxHeight: isCompact ? 300 : 400)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .overlay {
                            if let policy = runner.frozenLakePolicy {
                                PolicyOverlayView(map: runner.frozenLakeMap, policy: policy)
                                    .frame(maxWidth: isCompact ? .infinity : 400, maxHeight: isCompact ? 300 : 400)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                
            case .cartPole:
                if let snapshot = runner.cartPoleSnapshot {
                    CartPoleViewAdapter(snapshot: snapshot)
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: isCompact ? .infinity : 500, maxHeight: isCompact ? 200 : 350)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    evaluationPlaceholder(environment: "CartPole")
                }
                
            case .mountainCar:
                if let snapshot = runner.mountainCarSnapshot {
                    MountainCarCanvasView(snapshot: snapshot)
                        .aspectRatio(2.0, contentMode: .fit)
                        .frame(maxWidth: isCompact ? .infinity : 500, maxHeight: isCompact ? 200 : 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    evaluationPlaceholder(environment: "MountainCar")
                }
                
            case .mountainCarContinuous:
                if let snapshot = runner.mountainCarContinuousSnapshot {
                    MountainCarCanvasView(snapshot: snapshot)
                        .aspectRatio(2.0, contentMode: .fit)
                        .frame(maxWidth: isCompact ? .infinity : 500, maxHeight: isCompact ? 200 : 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    evaluationPlaceholder(environment: "MountainCar Continuous")
                }
            }
        }
    }
    
    private func evaluationPlaceholder(environment: String) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(1.5, contentMode: .fit)
            .frame(maxWidth: isCompact ? .infinity : 500)
            .overlay(Text("Ready to evaluate \(environment)"))
            .cornerRadius(12)
    }
    
    
    private var controlsView: some View {
        VStack(spacing: 12) {
            if isCompact {
                VStack(spacing: 12) {
                    HStack {
                        Text("Episodes:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("", value: $runner.episodesToRun, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .disabled(runner.isRunning)
                        
                        Spacer()
                        
                        Toggle("Visualize", isOn: $runner.showVisualization)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .disabled(runner.isRunning)
                        
                        Text("Visualize")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("Episodes to run:")
                        .foregroundStyle(.secondary)
                    
                    TextField("Episodes", value: $runner.episodesToRun, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .disabled(runner.isRunning)
                    
                    Spacer()
                    
                    Toggle("Show Visualization", isOn: $runner.showVisualization)
                        .disabled(runner.isRunning)
                }
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 16) {
                if runner.isRunning {
                    Button {
                        runner.stopEvaluation()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(minWidth: isCompact ? 100 : 120)
                    }
                    .buttonStyle(EvaluationButtonStyle(color: .red))
                } else {
                    Button {
                        runner.startEvaluation()
                    } label: {
                        Label(isCompact ? "Run" : "Run Evaluation", systemImage: "play.fill")
                            .font(.headline)
                            .frame(minWidth: isCompact ? 100 : 150)
                    }
                    .buttonStyle(EvaluationButtonStyle(color: .green))
                }
                
                if isCompact && !runner.episodeRewards.isEmpty {
                    Button {
                        showResults = true
                    } label: {
                        Label("Results", systemImage: "list.bullet")
                            .font(.headline)
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(EvaluationButtonStyle(color: .blue))
                }
            }
        }
    }
    
    
    private var compactResultsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results Summary")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    showResults = true
                }
                .font(.subheadline)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                resultSummaryItem(label: "Completed", value: "\(runner.currentEpisode)")
                resultSummaryItem(label: "Avg Reward", value: String(format: "%.1f", runner.averageReward))
                resultSummaryItem(label: "Avg Steps", value: String(format: "%.1f", runner.averageSteps))
                if runner.loadedAgent?.environmentType == .frozenLake {
                    resultSummaryItem(label: "Success", value: String(format: "%.0f%%", runner.successRate * 100))
                } else {
                    resultSummaryItem(label: "Total", value: String(format: "%.0f", runner.totalReward))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func resultSummaryItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var resultsSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Results")
                .font(.headline)
            
            if runner.episodeRewards.isEmpty {
                Text("Run evaluation to see results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    EvalResultRow(label: "Episodes Completed", value: "\(runner.currentEpisode)")
                    EvalResultRow(label: "Total Reward", value: String(format: "%.1f", runner.totalReward))
                    EvalResultRow(label: "Average Reward", value: String(format: "%.2f", runner.averageReward))
                    EvalResultRow(label: "Average Steps", value: String(format: "%.1f", runner.averageSteps))
                    
                    if runner.loadedAgent?.environmentType == .frozenLake {
                        EvalResultRow(label: "Success Rate", value: String(format: "%.1f%%", runner.successRate * 100))
                    }
                    
                    Divider()
                    
                    Text("Recent Episodes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    RecentEpisodesView(rewards: runner.episodeRewards)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 250)
        .background(Color.gray.opacity(0.05))
    }
    
    
    private var resultsSheet: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Episodes Completed", value: "\(runner.currentEpisode)")
                    LabeledContent("Total Reward", value: String(format: "%.1f", runner.totalReward))
                    LabeledContent("Average Reward", value: String(format: "%.2f", runner.averageReward))
                    LabeledContent("Average Steps", value: String(format: "%.1f", runner.averageSteps))
                    if runner.loadedAgent?.environmentType == .frozenLake {
                        LabeledContent("Success Rate", value: String(format: "%.1f%%", runner.successRate * 100))
                    }
                }
                
                Section("Recent Episodes") {
                    ForEach(Array(runner.episodeRewards.suffix(20).enumerated().reversed()), id: \.offset) { index, reward in
                        let episodeNum = runner.episodeRewards.count - (runner.episodeRewards.suffix(20).count - 1 - index)
                        HStack {
                            Text("Episode \(episodeNum)")
                            Spacer()
                            Text(String(format: "%.0f", reward))
                                .fontWeight(.medium)
                                .foregroundStyle(reward > 0 ? .green : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("Results")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showResults = false
                    }
                }
            }
        }
    }
}


private struct EvalStatItem: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }
}

private struct EvalResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}

private struct RecentEpisodesView: View {
    let rewards: [Double]
    
    private var recentRewards: [(index: Int, reward: Double)] {
        let suffix = rewards.suffix(20)
        let startIndex = max(0, rewards.count - 20)
        return suffix.enumerated().map { (startIndex + $0.offset + 1, $0.element) }.reversed()
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(recentRewards, id: \.index) { item in
                    HStack {
                        Text("Episode \(item.index)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f", item.reward))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(item.reward > 0 ? .green : .secondary)
                    }
                }
            }
        }
        .frame(maxHeight: 200)
    }
}

private struct EvaluationButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct EvalEnvironmentCard: View {
    let type: EnvironmentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(type.accentColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: type.iconName)
                        .font(.title)
                        .foregroundStyle(type.accentColor)
                }
                
                Text(type.displayName)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Text(type.defaultAlgorithm)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? type.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EvaluationView()
}

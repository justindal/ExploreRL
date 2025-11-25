//
//  EvaluationView.swift
//

import SwiftUI
import ExploreRLCore

struct EvaluationView: View {
    @State private var runner = EvaluationRunner()
    @State private var showLoadSheet = false
    @State private var selectedEnvironment: SavedAgent.EnvironmentType = .frozenLake
    
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
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Evaluation Mode")
                    .font(.title2)
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
                    Label("Load Different", systemImage: "arrow.down.doc")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    private var noAgentView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
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
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Test your trained agents without further training.\nSee how well they perform in their environment.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
                
                VStack(spacing: 16) {
                    Text("Select Environment")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        EnvironmentCard(
                            type: .frozenLake,
                            isSelected: selectedEnvironment == .frozenLake
                        ) {
                            selectedEnvironment = .frozenLake
                        }
                        
                        EnvironmentCard(
                            type: .cartPole,
                            isSelected: selectedEnvironment == .cartPole
                        ) {
                            selectedEnvironment = .cartPole
                        }
                    }
                }
                
                Button {
                    showLoadSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Load Agent")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Tip: Train an agent first, then save it to evaluate here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .padding()
    }
    
    private var evaluationContentView: some View {
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
    
    private var statsBar: some View {
        HStack(spacing: 24) {
            StatItem(
                title: "Episode",
                value: "\(runner.currentEpisode) / \(runner.episodesToRun)",
                icon: "number"
            )
            
            StatItem(
                title: "Step",
                value: "\(runner.currentStep)",
                icon: "figure.walk"
            )
            
            StatItem(
                title: "Reward",
                value: String(format: "%.1f", runner.episodeReward),
                icon: "star.fill"
            )
            
            if runner.loadedAgent?.environmentType == .frozenLake {
                StatItem(
                    title: "Success Rate",
                    value: String(format: "%.0f%%", runner.successRate * 100),
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            } else {
                StatItem(
                    title: "Avg Reward",
                    value: String(format: "%.1f", runner.averageReward),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
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
                        .frame(maxWidth: 400, maxHeight: 400)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .overlay {
                            if let policy = runner.frozenLakePolicy {
                                PolicyOverlayView(map: runner.frozenLakeMap, policy: policy)
                                    .frame(maxWidth: 400, maxHeight: 400)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                
            case .cartPole:
                if let snapshot = runner.cartPoleSnapshot {
                    CartPoleViewAdapter(snapshot: snapshot)
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: 500, maxHeight: 350)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: 500)
                        .overlay(Text("Ready to evaluate"))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 12) {
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
            
            HStack(spacing: 16) {
                if runner.isRunning {
                    Button {
                        runner.stopEvaluation()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(EvaluationButtonStyle(color: .red))
                } else {
                    Button {
                        runner.startEvaluation()
                    } label: {
                        Label("Run Evaluation", systemImage: "play.fill")
                            .font(.headline)
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(EvaluationButtonStyle(color: .green))
                }
            }
        }
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
                    ResultRow(label: "Episodes Completed", value: "\(runner.currentEpisode)")
                    ResultRow(label: "Total Reward", value: String(format: "%.1f", runner.totalReward))
                    ResultRow(label: "Average Reward", value: String(format: "%.2f", runner.averageReward))
                    ResultRow(label: "Average Steps", value: String(format: "%.1f", runner.averageSteps))
                    
                    if runner.loadedAgent?.environmentType == .frozenLake {
                        ResultRow(label: "Success Rate", value: String(format: "%.1f%%", runner.successRate * 100))
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
}

struct StatItem: View {
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

struct ResultRow: View {
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

struct RecentEpisodesView: View {
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

struct EvaluationButtonStyle: ButtonStyle {
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

struct EnvironmentCard: View {
    let type: SavedAgent.EnvironmentType
    let isSelected: Bool
    let action: () -> Void
    
    private var color: Color {
        type == .frozenLake ? .cyan : .orange
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: type.iconName)
                        .font(.title)
                        .foregroundStyle(color)
                }
                
                Text(type.displayName)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Text(type == .frozenLake ? "Tabular RL" : "Deep RL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EvaluationView()
}


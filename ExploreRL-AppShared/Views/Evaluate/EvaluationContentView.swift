//
//  EvaluationContentView.swift
//

import SwiftUI
import Gymnazo

struct EvaluationContentView: View {
    @Bindable var runner: EvaluationRunner
    let onBack: () -> Void
    @State private var showResults = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    runner.stopEvaluation()
                    onBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .sheet(isPresented: $showResults) {
            EvaluationResultsSheet(runner: runner)
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
                case .acrobot:
                    if let snapshot = runner.acrobotSnapshot {
                        AcrobotViewAdapter(snapshot: snapshot)
                            .aspectRatio(1.0, contentMode: .fit)
                            .cornerRadius(12)
                    }
                case .pendulum:
                    if let snapshot = runner.pendulumSnapshot {
                        PendulumViewAdapter(snapshot: snapshot)
                            .aspectRatio(1.0, contentMode: .fit)
                            .cornerRadius(12)
                    }
                case .lunarLander:
                    if let snapshot = runner.lunarLanderSnapshot {
                        LunarLanderViewAdapter(snapshot: snapshot)
                            .aspectRatio(600/400, contentMode: .fit)
                            .cornerRadius(12)
                    }
                case .lunarLanderContinuous:
                    if let snapshot = runner.lunarLanderContinuousSnapshot {
                        LunarLanderContinuousViewAdapter(snapshot: snapshot)
                            .aspectRatio(600/400, contentMode: .fit)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isCompact ? 300 : 400)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                EvaluationStatCard(
                    title: "Episode",
                    value: "\(runner.currentEpisode)/\(runner.episodesToRun)",
                    color: .blue
                )
                EvaluationStatCard(
                    title: "Step",
                    value: "\(runner.currentStep)",
                    color: .purple
                )
                EvaluationStatCard(
                    title: "Reward",
                    value: String(format: "%.0f", runner.episodeReward),
                    color: .cyan
                )
            }
            
            HStack(spacing: 12) {
                EvaluationStatCard(
                    title: "Avg Reward",
                    value: String(format: "%.1f", runner.averageReward),
                    color: .green
                )
                if runner.loadedAgent?.environmentType == .frozenLake {
                    EvaluationStatCard(
                        title: "Success",
                        value: String(format: "%.0f%%", runner.successRate * 100),
                        color: .orange
                    )
                } else {
                    EvaluationStatCard(
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

struct EvaluationStatCard: View {
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

struct EvaluationResultsSheet: View {
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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


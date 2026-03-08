//
//  LibraryDetailView.swift
//  ExploreRL
//

import SwiftUI

struct LibraryDetailView: View {
    let session: SavedSession
    let onLoad: (SavedSession) -> Void
    let onEvaluate: (SavedSession) -> Void
    let onExport: (SavedSession) -> Void
    let onRename: (SavedSession) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                metricsSection
                hyperparamsSection
                envSettingsSection
                actionsSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(session.name)
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Session Info")
                    .font(.headline)
                Spacer()
                AlgorithmBadge(text: session.algorithmType.rawValue)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                LabeledContent("Environment", value: session.environmentID)
                LabeledContent("Algorithm", value: session.algorithmType.rawValue)
                LabeledContent("Saved", value: session.savedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Total Steps", value: "\(session.trainingConfig.totalTimesteps)")
            }
            .font(.subheadline)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Progress")
                .font(.headline)

            let state = session.trainingState
            let progress = state.progress(totalTimesteps: session.trainingConfig.totalTimesteps)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(state.currentTimestep) / \(session.trainingConfig.totalTimesteps) steps")
                        .font(.caption)
                        .monospacedDigit()
                    Spacer()
                    Text(String(format: "%.1f%%", progress * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                ProgressView(value: progress)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120))],
                spacing: 12
            ) {
                MetricCard(
                    title: "Episodes",
                    value: "\(state.episodeCount)"
                )
                MetricCard(
                    title: "Avg Reward",
                    value: state.meanReward.map { String(format: "%.2f", $0) } ?? "-"
                )
                MetricCard(
                    title: "Best Reward",
                    value: state.rewardHistory.max().map { String(format: "%.2f", $0) } ?? "-"
                )
                MetricCard(
                    title: "Avg Length",
                    value: state.meanEpisodeLength.map { String(format: "%.1f", $0) } ?? "-"
                )
                if let explorationRate = state.explorationRate, explorationRate.isFinite {
                    MetricCard(
                        title: "Exploration",
                        value: String(format: "%.1f%%", explorationRate * 100)
                    )
                }
                if let loss = state.lossHistory.last, loss.isFinite,
                    state.criticLossHistory.last.map({
                        let scale = max(1.0, max(abs(loss), abs($0)))
                        return abs(loss - $0) > (1e-6 * scale)
                    }) ?? true
                {
                    MetricCard(
                        title: "Loss",
                        value: String(format: "%.4f", loss)
                    )
                }
                if let criticLoss = state.criticLossHistory.last, criticLoss.isFinite {
                    MetricCard(
                        title: "Critic Loss",
                        value: String(format: "%.4f", criticLoss)
                    )
                }
                if let actorLoss = state.actorLossHistory.last, actorLoss.isFinite {
                    MetricCard(
                        title: "Actor Loss",
                        value: String(format: "%.4f", actorLoss)
                    )
                }
                if let entropyCoef = state.entropyCoefHistory.last, entropyCoef.isFinite {
                    MetricCard(
                        title: "Entropy Coef",
                        value: String(format: "%.4f", entropyCoef)
                    )
                }
                if let qValue = state.qValueHistory.last, qValue.isFinite {
                    MetricCard(
                        title: "Avg Q-Value",
                        value: String(format: "%.2f", qValue)
                    )
                }
            }

        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

        TrainingChartsSection(state: session.trainingState)
    }



    @ViewBuilder
    private var hyperparamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hyperparameters")
                .font(.headline)

            let config = session.trainingConfig

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                LabeledContent("Seed", value: config.seed.isEmpty ? "None" : config.seed)

                switch session.algorithmType {
                case .qLearning, .sarsa:
                    let h = config.tabular
                    LabeledContent("Learning Rate", value: String(format: "%.4g", h.learningRate))
                    LabeledContent("Gamma", value: String(format: "%.4g", h.gamma))
                    LabeledContent("Epsilon", value: String(format: "%.4g", h.epsilon))
                    LabeledContent("Epsilon Decay", value: String(format: "%.4g", h.epsilonDecay))
                    LabeledContent("Min Epsilon", value: String(format: "%.4g", h.minEpsilon))
                case .dqn:
                    let h = config.dqn
                    LabeledContent("Learning Rate", value: String(format: "%.2e", h.learningRate))
                    LabeledContent("Gamma", value: String(format: "%.4g", h.gamma))
                    LabeledContent("Buffer Size", value: "\(h.bufferSize)")
                    LabeledContent("Batch Size", value: "\(h.batchSize)")
                    LabeledContent("Tau", value: String(format: "%.4g", h.tau))
                    LabeledContent("Exploration", value: String(format: "%.2f", h.explorationFraction))
                case .ppo:
                    let h = config.ppo
                    LabeledContent("Learning Rate", value: String(format: "%.2e", h.learningRate))
                    LabeledContent("Gamma", value: String(format: "%.4g", h.gamma))
                    LabeledContent("Rollout Steps", value: "\(h.nSteps)")
                    LabeledContent("Batch Size", value: "\(h.batchSize)")
                    LabeledContent("Epochs", value: "\(h.nEpochs)")
                    LabeledContent("Clip Range", value: String(format: "%.4g", h.clipRange))
                case .sac:
                    let h = config.sac
                    LabeledContent("Learning Rate", value: String(format: "%.2e", h.learningRate))
                    LabeledContent("Gamma", value: String(format: "%.4g", h.gamma))
                    LabeledContent("Buffer Size", value: "\(h.bufferSize)")
                    LabeledContent("Batch Size", value: "\(h.batchSize)")
                    LabeledContent("Tau", value: String(format: "%.4g", h.tau))
                case .td3:
                    let h = config.td3
                    LabeledContent("Learning Rate", value: String(format: "%.2e", h.learningRate))
                    LabeledContent("Gamma", value: String(format: "%.4g", h.gamma))
                    LabeledContent("Buffer Size", value: "\(h.bufferSize)")
                    LabeledContent("Batch Size", value: "\(h.batchSize)")
                    LabeledContent("Tau", value: String(format: "%.4g", h.tau))
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var filteredEnvSettingKeys: [String] {
        session.envSettings.keys
            .filter { !$0.hasPrefix("_") }
            .filter { key in
                if case .string(let s) = session.envSettings[key] { return !s.isEmpty }
                return true
            }
            .sorted()
    }

    @ViewBuilder
    private var envSettingsSection: some View {
        let keys = filteredEnvSettingKeys
        if !keys.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Environment")
                    .font(.headline)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(keys, id: \.self) { key in
                        if let value = session.envSettings[key] {
                            LabeledContent(formatSettingKey(key), value: value.displayString)
                        }
                    }
                }
                .font(.subheadline)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func formatSettingKey(_ key: String) -> String {
        key.split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    onLoad(session)
                } label: {
                    Label("Load in Training", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .modify { button in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        button
                            .buttonStyle(.glass(.regular.tint(.blue).interactive()))
                            .controlSize(.large)
                            #if os(macOS)
                            .tint(.blue)
                            #endif
                    } else {
                        button
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                }

                Button {
                    onEvaluate(session)
                } label: {
                    Label("Evaluate", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .modify { button in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        button
                            .buttonStyle(.glass(.regular.tint(.green).interactive()))
                            .controlSize(.large)
                            #if os(macOS)
                            .tint(.green)
                            #endif
                    } else {
                        button
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(.green)
                    }
                }
            }
            .modify { content in
                if #available(iOS 26.0, macOS 26.0, *) {
                    GlassEffectContainer(spacing: 14) { content }
                } else {
                    content
                }
            }

            Button {
                onExport(session)
            } label: {
                Label("Export Session", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .modify { button in
                if #available(iOS 26.0, macOS 26.0, *) {
                    button
                        .buttonStyle(.glass(.clear))
                        .controlSize(.large)
                } else {
                    button
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }

            Button {
                onRename(session)
            } label: {
                Label("Rename Session", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .modify { button in
                if #available(iOS 26.0, macOS 26.0, *) {
                    button
                        .buttonStyle(.glass(.clear))
                        .controlSize(.large)
                } else {
                    button
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }

            Divider()

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete Session", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .confirmationDialog(
                "Delete Session?",
                isPresented: $showDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete this saved session and its trained model.")
            }
            .modify { button in
                if #available(iOS 26.0, macOS 26.0, *) {
                    button
                        .buttonStyle(.glass(.regular.tint(.red).interactive()))
                        .controlSize(.large)
                        #if os(macOS)
                        .tint(.red)
                        #endif
                } else {
                    button
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

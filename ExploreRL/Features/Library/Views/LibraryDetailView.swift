//
//  LibraryDetailView.swift
//  ExploreRL
//

import SwiftUI

struct LibraryDetailView: View {
    let session: SavedSession
    let onLoad: (SavedSession) -> Void
    let onEvaluate: (SavedSession) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var exportURL: URL?
    @State private var exportError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                metricsSection
                hyperparamsSection
                envSettingsSection
                configSection
                actionsSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(session.name)
        .alert("Delete Session?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete this saved session and its trained model.")
        }
        .alert(
            "Export Failed",
            isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
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
                    title: "Avg Length",
                    value: state.meanEpisodeLength.map { String(format: "%.1f", $0) } ?? "-"
                )
                if state.explorationRate != nil {
                    MetricCard(
                        title: "Exploration",
                        value: state.explorationRate.map { String(format: "%.1f%%", $0 * 100) } ?? "-"
                    )
                }
            }

        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

        TrainingChartsSection(state: session.trainingState)
    }

    @ViewBuilder
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)

            let config = session.trainingConfig
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                LabeledContent("Seed", value: config.seed.isEmpty ? "None" : config.seed)
                LabeledContent("Render", value: config.renderDuringTraining ? "On" : "Off")
            }
            .font(.subheadline)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
                case .sac:
                    let h = config.sac
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
                    Text("Load in Training")
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
                    Text("Evaluate")
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

            Button {
                do {
                    exportURL = try SessionStorage.shared.exportSession(session)
                } catch {
                    exportError = error.localizedDescription
                }
            } label: {
                Label("Export Session", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .modify { button in
                if #available(iOS 26.0, macOS 26.0, *) {
                    button
                        .buttonStyle(.glass(.regular.tint(.indigo).interactive()))
                        .controlSize(.large)
                        #if os(macOS)
                        .tint(.indigo)
                        #endif
                } else {
                    button
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share Export", systemImage: "square.and.arrow.up.on.square")
                        .frame(maxWidth: .infinity)
                }
                .modify { link in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        link
                            .buttonStyle(.glass(.regular.tint(.indigo).interactive()))
                            .controlSize(.large)
                            #if os(macOS)
                            .tint(.indigo)
                            #endif
                    } else {
                        link
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                    }
                }
            }

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete Session", systemImage: "trash")
                    .frame(maxWidth: .infinity)
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
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

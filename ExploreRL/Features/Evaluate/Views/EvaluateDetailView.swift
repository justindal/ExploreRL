//
//  EvaluateDetailView.swift
//  ExploreRL
//

import Gymnazo
import SwiftUI

struct EvaluateDetailView: View {
    let session: SavedSession
    @Bindable var vm: EvaluateViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sessionHeader
                topSection
                if !vm.state.episodeRewards.isEmpty {
                    EvaluationResults(state: vm.state)
                }
            }
            .frame(maxWidth: 960, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle(session.name)
        .task(id: session.id) {
            await vm.loadSession(session)
        }
    }

    @ViewBuilder
    private var topSection: some View {
        if let env = vm.env, sizeClass == .regular {
            HStack(alignment: .top, spacing: 20) {
                envSection(env: env)
                controlsSection
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
            }
        } else {
            if let env = vm.env {
                envSection(env: env)
                    .frame(maxWidth: .infinity)
            }
            controlsSection
        }
    }

    @ViewBuilder
    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Agent Info")
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
                LabeledContent("Steps Trained", value: "\(session.trainingState.currentTimestep)")
                LabeledContent("Episodes Trained", value: "\(session.trainingState.episodeCount)")
                if let reward = session.trainingState.meanReward {
                    LabeledContent("Training Avg Reward", value: String(format: "%.2f", reward))
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func envSection(env: any Env) -> some View {
        EnvView(
            env: env,
            snapshot: vm.renderSnapshot,
            renderVersion: vm.state.renderVersion
        )
    }

    @ViewBuilder
    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evaluation")
                .font(.headline)

            if vm.state.status == .running {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Episode \(vm.state.currentEpisode) / \(vm.state.totalEpisodes)")
                            .font(.caption)
                            .monospacedDigit()
                        Spacer()
                        Text(String(format: "%.0f%%", vm.state.progress * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressView(value: vm.state.progress)
                }
            }

            settingsRow
            actionButtons
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var settingsRow: some View {
        let isRunning = vm.state.status == .running
        let isLoading = vm.state.status == .loading

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Episodes:")
                    .font(.subheadline)
                TextField("", value: $vm.state.totalEpisodes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .disabled(isRunning || isLoading)
                Spacer()
                Toggle("Render", isOn: $vm.state.renderEnabled)
                    .font(.subheadline)
                    .fixedSize()
                    .disabled(isRunning || isLoading)
            }

            if vm.state.renderEnabled {
                let sliderBinding = Binding<Double>(
                    get: { vm.state.renderFPS <= 0 ? 121 : Double(min(120, vm.state.renderFPS)) },
                    set: { value in
                        let v = Int(value.rounded())
                        vm.state.renderFPS = v >= 121 ? 0 : max(1, min(120, v))
                    }
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("FPS")
                            .font(.subheadline)
                        Spacer()
                        Text(vm.state.renderFPS <= 0 ? "Unlimited" : "\(vm.state.renderFPS) fps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: sliderBinding, in: 1...121)
                        .disabled(isRunning || isLoading)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            switch vm.state.status {
            case .running:
                Button {
                    vm.stopEvaluation()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
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
                            .tint(.red)
                    }
                }

            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)

            default:
                Button {
                    vm.startEvaluation()
                } label: {
                    Label("Run Evaluation", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(vm.env == nil)
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
        }
        .modify { content in
            if #available(iOS 26.0, macOS 26.0, *) {
                GlassEffectContainer(spacing: 14) {
                    content
                }
            } else {
                content
            }
        }
    }
}

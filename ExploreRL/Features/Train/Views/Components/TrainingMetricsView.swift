//
//  TrainingMetricsView.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-27.
//

import Gymnazo
import SwiftUI

struct TrainingMetricsView: View {
    let trainingState: TrainingState
    let algorithm: AlgorithmType

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Label("Live metrics", systemImage: "waveform.path.ecg")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppLayout.compactSpacing
            ) {
                coreMetrics

                if algorithm == .qLearning || algorithm == .sarsa || algorithm == .dqn {
                    MetricCard(
                        title: "Exploration",
                        value: trainingState.explorationRate.map {
                            $0.formatted(.percent.precision(.fractionLength(1)))
                        } ?? "-"
                    )
                }

                algorithmSpecificMetrics
            }
        }
        .padding(AppLayout.panelPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius))
    }

    @ViewBuilder
    private var coreMetrics: some View {
        MetricCard(
            title: "Avg Reward",
            value: trainingState.meanReward.map {
                $0.formatted(.number.precision(.fractionLength(2)))
            } ?? "-"
        )
        MetricCard(
            title: "Best Reward",
            value: trainingState.rewardHistory.max().map {
                $0.formatted(.number.precision(.fractionLength(2)))
            } ?? "-"
        )
        MetricCard(
            title: "Avg Length",
            value: trainingState.meanEpisodeLength.map {
                $0.formatted(.number.precision(.fractionLength(1)))
            } ?? "-"
        )
    }

    @ViewBuilder
    private var algorithmSpecificMetrics: some View {
        switch algorithm {
        case .qLearning, .sarsa:
            EmptyView()
        case .dqn:
            dqnMetrics
        case .ppo:
            ppoMetrics
        case .sac:
            sacMetrics
        case .td3:
            td3Metrics
        }
    }

    @ViewBuilder
    private var dqnMetrics: some View {
        MetricCard(
            title: "Loss",
            value: trainingState.lossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Learning Rate",
            value: trainingState.learningRateHistory.last.map { formatLearningRate($0) } ?? "-"
        )
    }

    @ViewBuilder
    private var ppoMetrics: some View {
        MetricCard(
            title: "Loss",
            value: trainingState.lossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Critic Loss",
            value: trainingState.criticLossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Actor Loss",
            value: trainingState.actorLossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Entropy Coef",
            value: trainingState.entropyCoefHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Learning Rate",
            value: trainingState.learningRateHistory.last.map { formatLearningRate($0) } ?? "-"
        )
    }

    @ViewBuilder
    private var sacMetrics: some View {
        MetricCard(
            title: "Critic Loss",
            value: trainingState.criticLossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Actor Loss",
            value: trainingState.actorLossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Entropy Coef",
            value: trainingState.entropyCoefHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Learning Rate",
            value: trainingState.learningRateHistory.last.map { formatLearningRate($0) } ?? "-"
        )
    }

    @ViewBuilder
    private var td3Metrics: some View {
        MetricCard(
            title: "Critic Loss",
            value: trainingState.criticLossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Actor Loss",
            value: trainingState.actorLossHistory.last.map { formatValue($0) } ?? "-"
        )
        MetricCard(
            title: "Learning Rate",
            value: trainingState.learningRateHistory.last.map { formatLearningRate($0) } ?? "-"
        )
    }

    private func formatValue(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(4)))
    }

    private func formatLearningRate(_ value: Double) -> String {
        if value < 0.001 {
            return String(format: "%.1e", value)
        } else {
            return value.formatted(.number.precision(.fractionLength(4)))
        }
    }
}

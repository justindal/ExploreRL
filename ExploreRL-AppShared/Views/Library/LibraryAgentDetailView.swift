//
//  LibraryAgentDetailView.swift
//

import SwiftUI

struct LibraryAgentDetailView: View {
    let agentSummary: SavedAgentSummary
    @State private var fullAgent: SavedAgent?
    @State private var isLoading = true

    private var environmentColor: Color {
        agentSummary.environmentType.accentColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                statsGrid

                if let agent = fullAgent {
                    hyperparametersSection(agent: agent)
                    AgentDataVisualizationView(agent: agent)
                } else if isLoading {
                    ProgressView("Loading agent data...")
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                timestampsSection
            }
            .padding()
        }
        #if os(iOS)
            .navigationTitle(agentSummary.name)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: agentSummary.id) {
            await loadAgent()
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(environmentColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: agentSummary.environmentType.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(environmentColor)
            }

            VStack(spacing: 4) {
                Text(agentSummary.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 8) {
                    Text(agentSummary.algorithmType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(6)

                    Text(agentSummary.environmentType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(environmentColor.opacity(0.2))
                        .foregroundStyle(environmentColor)
                        .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            LibraryStatBox(
                title: "Episodes",
                value: "\(agentSummary.episodesTrained)",
                icon: "number",
                color: .blue
            )

            if let successRate = agentSummary.successRate {
                LibraryStatBox(
                    title: "Success Rate",
                    value: String(format: "%.0f%%", successRate * 100),
                    icon: "checkmark.circle",
                    color: .green
                )
            } else {
                LibraryStatBox(
                    title: "Best Reward",
                    value: formatDisplayValue(agentSummary.bestReward),
                    icon: "star",
                    color: .orange
                )
            }

            LibraryStatBox(
                title: "Avg Reward",
                value: formatDisplayValue(agentSummary.averageReward),
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )

            LibraryStatBox(
                title: "File Size",
                value: agentSummary.formattedFileSize,
                icon: "doc",
                color: .gray
            )
        }
    }

    private func hyperparametersSection(agent: SavedAgent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hyperparameters")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(Array(agent.hyperparameters.keys.sorted()), id: \.self)
                { key in
                    HStack {
                        Text(formatKey(key))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(
                            formatHyperparameterValue(
                                agent.hyperparameters[key] ?? 0
                            )
                        )
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    private var timestampsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Created")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(agentSummary.createdAt, style: .date)
            }
            .font(.caption)

            HStack {
                Text("Last Updated")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(agentSummary.updatedAt, style: .date)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    private func loadAgent() async {
        isLoading = true
        fullAgent = nil
        let agentId = agentSummary.id
        do {
            let agent = try AgentStorage.shared.loadAgent(id: agentId)
            self.fullAgent = agent
        } catch {
            print("Failed to load agent: \(error)")
        }
        self.isLoading = false
    }

    private func formatKey(_ key: String) -> String {
        var result = ""
        for char in key {
            if char.isUppercase {
                result += " "
            }
            result += String(char)
        }
        return result.prefix(1).uppercased() + result.dropFirst()
    }

    private func formatHyperparameterValue(_ value: Double) -> String {
        let mag = value.magnitude

        if value == value.rounded() && mag < 100_000 {
            return String(format: "%.0f", value)
        }

        let precision: Int
        switch mag {
        case 0..<0.0001 where value != 0:
            precision = 6
        case 0..<0.01:
            precision = 5
        case 0..<1:
            precision = 4
        default:
            precision = 3
        }

        let format = "%.\(precision)f"
        let formatted = String(format: format, value)

        return trimTrailingZeros(formatted)
    }

    private func trimTrailingZeros(_ string: String) -> String {
        var result = string
        while result.hasSuffix("0") && result.contains(".") {
            result.removeLast()
        }
        if result.hasSuffix(".") {
            result.removeLast()
        }
        return result
    }

    private func formatDisplayValue(_ value: Double) -> String {
        if value == value.rounded() && Swift.abs(value) < 10000 {
            return String(format: "%.0f", value)
        }
        let formatted = String(format: "%.1f", value)
        return trimTrailingZeros(formatted)
    }
}

struct LibraryStatBox: View {
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

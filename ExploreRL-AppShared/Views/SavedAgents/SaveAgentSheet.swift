//
//  SaveAgentSheet.swift
//

import SwiftUI

struct SaveAgentSheet: View {
    let environmentType: SavedAgent.EnvironmentType
    let algorithmType: String
    let episodesTrained: Int
    let currentReward: Double
    let loadedAgentId: UUID?
    let loadedAgentName: String?
    let onSave: (String) throws -> SavedAgent
    let onUpdate: ((UUID, String) throws -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var agentName: String = ""
    @State private var saveMode: SaveMode = .new
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedSuccessfully = false
    
    enum SaveMode {
        case new
        case update
    }
    
    private var environmentColor: Color {
        environmentType == .frozenLake ? .cyan : .orange
    }
    
    private var canUpdate: Bool {
        loadedAgentId != nil && onUpdate != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            VStack(spacing: 20) {
                if canUpdate {
                    saveModeSection
                }
                
                nameInputSection
                
                statsSection
                
                if let error = errorMessage {
                    errorView(error)
                }
                
                if savedSuccessfully {
                    successView
                }
                
                Spacer()
                
                actionButtons
            }
            .padding(24)
        }
        #if os(macOS)
        .frame(width: 420, height: canUpdate ? 500 : 440)
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .onAppear {
            if let existingName = loadedAgentName {
                agentName = existingName
                saveMode = .update
            } else {
                agentName = generateDefaultName()
                saveMode = .new
            }
        }
    }
    
    private func generateDefaultName() -> String {
        let envName = environmentType == .frozenLake ? "FrozenLake" : "CartPole"
        let randomSuffix = String((0..<6).map { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()! })
        return "\(envName)-\(randomSuffix)"
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(environmentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: environmentType.iconName)
                    .font(.title2)
                    .foregroundStyle(environmentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Save Agent")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(environmentType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.gray.opacity(0.08))
    }
    
    private var saveModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Save Option")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                SaveModeButton(
                    title: "Update Existing",
                    subtitle: loadedAgentName ?? "Original",
                    icon: "arrow.triangle.2.circlepath",
                    isSelected: saveMode == .update
                ) {
                    saveMode = .update
                    agentName = loadedAgentName ?? agentName
                }
                
                SaveModeButton(
                    title: "Save as New",
                    subtitle: "Create copy",
                    icon: "plus.square.on.square",
                    isSelected: saveMode == .new
                ) {
                    saveMode = .new
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM d, h:mm a"
                    agentName = "\(algorithmType) - \(dateFormatter.string(from: Date()))"
                }
            }
        }
    }
    
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(saveMode == .update ? "Update Name (Optional)" : "Agent Name")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            TextField("Enter a name...", text: $agentName)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Summary")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "cpu",
                    label: "Algorithm",
                    value: algorithmType,
                    color: .blue
                )
                
                StatCard(
                    icon: "number",
                    label: "Episodes",
                    value: "\(episodesTrained)",
                    color: .purple
                )
                
                StatCard(
                    icon: "star.fill",
                    label: "Reward",
                    value: String(format: "%.2f", currentReward),
                    color: .orange
                )
            }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            
            Text(error)
                .font(.subheadline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.1))
        )
    }
    
    private var successView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
            
            Text("Agent saved successfully!")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            Button {
                saveAgent()
            } label: {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                    }
                    Text(isSaving ? "Saving..." : "Save Agent")
                }
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(agentName.isEmpty || isSaving || savedSuccessfully)
        }
    }
    
    private func saveAgent() {
        isSaving = true
        errorMessage = nil
        
        do {
            if saveMode == .update, let agentId = loadedAgentId, let updateFn = onUpdate {
                try updateFn(agentId, agentName)
            } else {
                _ = try onSave(agentName)
            }
            savedSuccessfully = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
}

private struct SaveModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview("New Agent") {
    SaveAgentSheet(
        environmentType: .frozenLake,
        algorithmType: "Q-Learning",
        episodesTrained: 500,
        currentReward: 0.75,
        loadedAgentId: nil,
        loadedAgentName: nil,
        onSave: { _ in throw AgentStorageError.agentNotFound },
        onUpdate: nil
    )
}

#Preview("Loaded Agent") {
    SaveAgentSheet(
        environmentType: .cartPole,
        algorithmType: "DQN",
        episodesTrained: 1500,
        currentReward: 195.5,
        loadedAgentId: UUID(),
        loadedAgentName: "My Best Agent",
        onSave: { _ in throw AgentStorageError.agentNotFound },
        onUpdate: { _, _ in }
    )
}


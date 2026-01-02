//
//  SharedComponents.swift
//

import SwiftUI


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
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}


struct EnvironmentCard: View {
    let type: EnvironmentType
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: isCompact ? 8 : 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: isCompact ? 50 : 60, height: isCompact ? 50 : 60)
                    
                    Image(systemName: type.iconName)
                        .font(.system(size: isCompact ? 22 : 28))
                        .foregroundStyle(isSelected ? type.color : .secondary)
                }
                
                Text(type.displayName)
                    .font(isCompact ? .caption : .subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(isCompact ? 12 : 16)
            .frame(width: isCompact ? 100 : 140, height: isCompact ? 100 : 130)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? type.color : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}


struct LoadingOverlay: View {
    var message: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

struct LoadingPlaceholder: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
    }
}


@available(iOS 17.0, macOS 14.0, *)
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}


struct ResultRow: View {
    let episode: Int
    let reward: Double
    let steps: Int
    var success: Bool? = nil
    
    var body: some View {
        HStack {
            Text("Episode \(episode)")
                .font(.subheadline)
            
            Spacer()
            
            if let success = success {
                Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(success ? .green : .red)
            }
            
            Text(String(format: "%.1f", reward))
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
            
            Text("\(steps) steps")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}


struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}


extension EnvironmentType {
    var color: Color {
        switch self {
        case .frozenLake: return .cyan
        case .blackjack: return .mint
        case .taxi: return .yellow
        case .cliffWalking: return .brown
        case .cartPole: return .orange
        case .mountainCar: return .green
        case .mountainCarContinuous: return .purple
        case .acrobot: return .red
        case .pendulum: return .indigo
        case .lunarLander: return .blue
        case .lunarLanderContinuous: return .teal
        case .carRacing: return .pink
        case .carRacingDiscrete: return .gray
        }
    }
    
    var accessibleForeground: Color {
        switch self {
        case .frozenLake, .mountainCar, .blackjack, .taxi, .cliffWalking, .carRacingDiscrete: return .black
        case .cartPole, .mountainCarContinuous, .acrobot, .pendulum, .lunarLander, .lunarLanderContinuous, .carRacing: return .white
        }
    }
}


#Preview("Stat Item") {
    HStack(spacing: 24) {
        StatItem(title: "Episode", value: "42", icon: "number")
        StatItem(title: "Success", value: "85%", icon: "checkmark.circle", color: .green)
    }
    .padding()
}

#Preview("Stat Card") {
    HStack {
        StatCard(title: "Episodes", value: "1,234", icon: "number.circle.fill", color: .blue)
        StatCard(title: "Best Reward", value: "195.0", icon: "trophy.fill", color: .orange)
    }
    .padding()
}

#Preview("Environment Card") {
    HStack {
        EnvironmentCard(type: .frozenLake, isSelected: true) {}
        EnvironmentCard(type: .cartPole, isSelected: false) {}
    }
    .padding()
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("Empty State") {
    EmptyStateView(
        icon: "tray",
        title: "No Saved Agents",
        message: "Train an agent and save it to see it here.",
        actionTitle: "Start Training"
    ) {}
}


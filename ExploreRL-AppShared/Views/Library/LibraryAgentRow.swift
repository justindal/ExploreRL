//
//  LibraryAgentRow.swift
//

import SwiftUI

enum LibrarySortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"
    case episodesHigh = "Most Episodes"
    case rewardHigh = "Best Reward"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dateNewest: return "arrow.down.circle"
        case .dateOldest: return "arrow.up.circle"
        case .nameAZ: return "textformat.abc"
        case .nameZA: return "textformat.abc"
        case .episodesHigh: return "number.circle"
        case .rewardHigh: return "star.circle"
        }
    }
}

struct LibraryAgentRow: View {
    let agent: SavedAgentSummary
    
    private var environmentColor: Color {
        agent.environmentType.accentColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(environmentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: agent.environmentType.iconName)
                    .font(.title3)
                    .foregroundStyle(environmentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(agent.algorithmType)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    
                    Text("\(agent.episodesTrained) ep")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let successRate = agent.successRate {
                    Text(String(format: "%.0f%%", successRate * 100))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                } else {
                    Text(String(format: "%.0f", agent.bestReward))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
                
                Text(formatRelativeTime(agent.updatedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(minutes) min\(minutes == 1 ? "" : "s")"
        } else if hours < 24 {
            return "\(hours) hr\(hours == 1 ? "" : "s")"
        } else if days < 7 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}


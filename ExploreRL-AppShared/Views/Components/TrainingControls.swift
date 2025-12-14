//
//  TrainingControls.swift
//

import SwiftUI

struct TrainingButtonStyle: ButtonStyle {
    let color: Color
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.4)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct TrainingCompleteBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Training Complete!")
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

struct WarmupBanner: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Warming up replay buffer...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            Text("\(Int(progress * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minWidth: 220)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

struct TrainingProgressView: View {
    let current: Int
    let total: Int
    let totalEpisodesTrained: Int
    let accumulatedTrainingTimeSeconds: TimeInterval
    let trainingSessionStartDate: Date?
    let isTraining: Bool
    let color: Color
    
    init(
        current: Int,
        total: Int,
        totalEpisodesTrained: Int = 0,
        accumulatedTrainingTimeSeconds: TimeInterval = 0,
        trainingSessionStartDate: Date? = nil,
        isTraining: Bool = false,
        color: Color
    ) {
        self.current = current
        self.total = total
        self.totalEpisodesTrained = totalEpisodesTrained
        self.accumulatedTrainingTimeSeconds = accumulatedTrainingTimeSeconds
        self.trainingSessionStartDate = trainingSessionStartDate
        self.isTraining = isTraining
        self.color = color
    }
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
    
    private func totalTrainingTimeSeconds(at date: Date) -> TimeInterval {
        guard isTraining, let start = trainingSessionStartDate else {
            return accumulatedTrainingTimeSeconds
        }
        return accumulatedTrainingTimeSeconds + date.timeIntervalSince(start)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let safeSeconds = max(0, seconds)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: safeSeconds) ?? "00:00:00"
    }
    
    private func episodesPerMinute(totalTimeSeconds: TimeInterval) -> Double? {
        guard totalEpisodesTrained > 0, totalTimeSeconds > 0 else { return nil }
        return (Double(totalEpisodesTrained) / totalTimeSeconds) * 60.0
    }
    
    private func etaSeconds(totalTimeSeconds: TimeInterval) -> TimeInterval? {
        guard total > 0 else { return nil }
        let remainingEpisodes = max(0, total - current)
        guard remainingEpisodes > 0 else { return 0 }
        guard let epm = episodesPerMinute(totalTimeSeconds: totalTimeSeconds), epm > 0 else { return nil }
        return (Double(remainingEpisodes) / epm) * 60.0
    }
    
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            let totalTime = totalTrainingTimeSeconds(at: context.date)
            let epm = episodesPerMinute(totalTimeSeconds: totalTime)
            let eta = etaSeconds(totalTimeSeconds: totalTime)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Training Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("Episode \(current) / \(max(total, 0))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Spacer()
                    Text("Total trained \(formatDuration(totalTime))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("Rate \(epm.map { String(format: "%.1f", $0) } ?? "--") eps/min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Spacer()
                    Text("ETA \(eta.map(formatDuration) ?? "--:--:--")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
    }
}


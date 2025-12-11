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
    let color: Color
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Training Progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.subheadline)
                    .fontWeight(.medium)
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


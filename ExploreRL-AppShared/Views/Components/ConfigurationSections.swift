//
//  ConfigurationSections.swift
//

import SwiftUI

struct SpeedControlSection: View {
    @Binding var renderEnabled: Bool
    @Binding var targetFPS: Double
    @Binding var turboMode: Bool
    let isTraining: Bool
    let showTurboMode: Bool
    let onRenderChange: (() -> Void)?
    
    @State private var showRenderConfirm = false
    @State private var proposedRenderEnabled = true
    
    init(
        renderEnabled: Binding<Bool>,
        targetFPS: Binding<Double>,
        turboMode: Binding<Bool> = .constant(false),
        isTraining: Bool,
        showTurboMode: Bool = true,
        onRenderChange: (() -> Void)? = nil
    ) {
        self._renderEnabled = renderEnabled
        self._targetFPS = targetFPS
        self._turboMode = turboMode
        self.isTraining = isTraining
        self.showTurboMode = showTurboMode
        self.onRenderChange = onRenderChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speed & Run Control")
                .font(.headline)
            
            Toggle("Render Mode", isOn: Binding(
                get: { renderEnabled },
                set: { newValue in
                    guard newValue != renderEnabled else { return }
                    proposedRenderEnabled = newValue
                    showRenderConfirm = true
                }
            ))
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                Text("Switching render mode resets the environment.")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            
            if showTurboMode {
                Toggle("Turbo Mode", isOn: $turboMode)
            }
            
            if renderEnabled && !turboMode {
                HStack {
                    Text("Target FPS")
                    Spacer()
                    Text("\(Int(targetFPS))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $targetFPS, in: 1...120, step: 1)
            }
        }
        .alert("Switch Render Mode?", isPresented: $showRenderConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Switch", role: .destructive) {
                renderEnabled = proposedRenderEnabled
                onRenderChange?()
            }
        } message: {
            Text("This will reset the environment and stop any current training. If you have unsaved progress, save your agent first.")
        }
    }
}

struct TrainingLimitsSection: View {
    @Binding var episodesPerRun: Int
    @Binding var maxStepsPerEpisode: Int
    let isTraining: Bool
    let episodesRange: ClosedRange<Double>
    let stepsRange: ClosedRange<Double>
    let stepsStep: Double
    
    init(
        episodesPerRun: Binding<Int>,
        maxStepsPerEpisode: Binding<Int>,
        isTraining: Bool,
        episodesRange: ClosedRange<Double> = 10...5000,
        stepsRange: ClosedRange<Double> = 50...2000,
        stepsStep: Double = 50
    ) {
        self._episodesPerRun = episodesPerRun
        self._maxStepsPerEpisode = maxStepsPerEpisode
        self.isTraining = isTraining
        self.episodesRange = episodesRange
        self.stepsRange = stepsRange
        self.stepsStep = stepsStep
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Training Limits")
                .font(.headline)
            
            let episodesBinding = Binding<Double>(
                get: { Double(episodesPerRun) },
                set: { episodesPerRun = max(1, Int($0.rounded())) }
            )
            HStack {
                Text("Episodes / Run")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                TextField("", value: $episodesPerRun, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .disabled(isTraining)
            }
            Slider(value: episodesBinding, in: episodesRange)
                .disabled(isTraining)
            
            let maxStepsBinding = Binding<Double>(
                get: { Double(maxStepsPerEpisode) },
                set: { maxStepsPerEpisode = Int($0) }
            )
            HStack {
                Text("Max Steps / Ep")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text("\(maxStepsPerEpisode)")
                    .monospacedDigit()
            }
            Slider(value: maxStepsBinding, in: stepsRange, step: stepsStep)
                .disabled(isTraining)
        }
    }
}

struct EnvironmentInfoSection: View {
    let title: String
    let info: [(label: String, value: String)]
    
    init(title: String = "Environment Info", info: [(label: String, value: String)]) {
        self.title = title
        self.info = info
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            ForEach(info, id: \.label) { item in
                HStack {
                    Text(item.label)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.value)
                        .font(.system(.body, design: .monospaced))
                }
                .font(.caption)
            }
        }
    }
}

struct ConfigurationContainer<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            content()
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }
}


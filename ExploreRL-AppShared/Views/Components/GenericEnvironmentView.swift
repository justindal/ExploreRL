//
//  GenericEnvironmentView.swift
//
//  Reusable view components for environment training views.
//

import SwiftUI


struct EnvironmentHeaderView<Runner: EnvironmentRunner>: View {
    @Bindable var runner: Runner
    let title: String
    let subtitle: String?
    let showUnsavedIndicator: Bool
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(runner: Runner, title: String, subtitle: String? = nil, showUnsavedIndicator: Bool = false) {
        self.runner = runner
        self.title = title
        self.subtitle = subtitle
        self.showUnsavedIndicator = showUnsavedIndicator
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(title)
                    .font(horizontalSizeClass == .compact ? .title : .largeTitle)
                    .bold()
                
                if showUnsavedIndicator {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                        .help("Unsaved changes")
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ViewThatFits(in: .horizontal) {
                HStack {
                    Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                    Spacer()
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    Spacer()
                    Label(String(format: "Reward: %.1f", runner.episodeReward), systemImage: "trophy")
                }
                
                VStack(alignment: .leading) {
                    Label("\(runner.totalEpisodesTrained) Completed", systemImage: "checkmark.circle")
                    Label("Step \(runner.currentStep)", systemImage: "figure.walk")
                    Label(String(format: "Reward: %.1f", runner.episodeReward), systemImage: "trophy")
                }
            }
            .font(.headline)
            .padding(.top, 5)
        }
    }
}


struct TrainingControlsView<Runner: EnvironmentRunner>: View {
    @Bindable var runner: Runner
    let accentColor: Color
    let showProgress: Bool
    let onReset: () -> Void
    
    init(runner: Runner, accentColor: Color = .blue, showProgress: Bool = true, onReset: @escaping () -> Void) {
        self.runner = runner
        self.accentColor = accentColor
        self.showProgress = showProgress
        self.onReset = onReset
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if showProgress && !runner.renderEnabled && runner.isTraining {
                TrainingProgressView(
                    current: runner.episodeMetrics.count,
                    total: runner.episodesPerRun,
                    color: accentColor
                )
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 16) {
                if runner.isTraining {
                    Button(action: { runner.stopTraining() }) {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(TrainingButtonStyle(color: .red))
                } else {
                    Button(action: { runner.startTraining() }) {
                        Label("Start Training", systemImage: "play.fill")
                            .font(.headline)
                            .frame(minWidth: 140)
                    }
                    .buttonStyle(TrainingButtonStyle(color: accentColor))
                    
                    Button(action: onReset) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(TrainingButtonStyle(color: Color(.systemGray)))
                }
            }
        }
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
                Text("\(current) / \(total)")
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


struct InspectorPanelView<Settings: View, Charts: View>: View {
    @Binding var selectedTab: InspectorTab
    let settings: () -> Settings
    let charts: () -> Charts
    
    enum InspectorTab: String, CaseIterable, Identifiable {
        case settings = "Settings"
        case charts = "Charts"
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Picker("", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .settings:
                        settings()
                            .transition(.move(edge: .leading))
                    case .charts:
                        charts()
                            .transition(.move(edge: .trailing))
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
    }
}


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
            
            if renderEnabled && showTurboMode {
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


//
//  ConfigurationHelpers.swift
//

import SwiftUI

/// Creates a clamped binding for Double values
func clampedBinding(
    for binding: Binding<Double>,
    range: ClosedRange<Double>,
    step: Double? = nil
) -> Binding<Double> {
    Binding<Double>(
        get: { binding.wrappedValue },
        set: {
            var newValue = $0
            if let step = step {
                newValue = (newValue / step).rounded() * step
            }
            binding.wrappedValue = min(max(newValue, range.lowerBound), range.upperBound)
        }
    )
}

/// Creates a clamped binding that converts Float to Double for slider compatibility.
func clampedBinding(
    for floatBinding: Binding<Float>,
    range: ClosedRange<Double>,
    step: Double? = nil
) -> Binding<Double> {
    Binding<Double>(
        get: { Double(floatBinding.wrappedValue) },
        set: {
            var newValue = $0
            if let step = step {
                newValue = (newValue / step).rounded() * step
            }
            floatBinding.wrappedValue = Float(min(max(newValue, range.lowerBound), range.upperBound))
        }
    )
}

/// Creates a clamped binding that converts Int to Double for slider compatibility.
func clampedIntBinding(
    _ binding: Binding<Int>,
    range: ClosedRange<Double>,
    step: Double = 1
) -> Binding<Double> {
    Binding<Double>(
        get: { Double(binding.wrappedValue) },
        set: {
            let clamped = min(range.upperBound, max(range.lowerBound, $0.rounded()))
            binding.wrappedValue = Int(clamped)
        }
    )
}

struct EnvironmentInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
        .font(.caption)
    }
}

/// A reusable hyperparameter slider row with info button, value display, and slider.
struct HyperparameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let decimals: Int
    let infoTitle: String
    let infoDescription: String
    let infoIcon: String
    let isDisabled: Bool
    
    @State private var showInfo = false
    
    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double? = nil,
        decimals: Int = 2,
        infoTitle: String,
        infoDescription: String,
        infoIcon: String = "info.circle",
        isDisabled: Bool = false
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.decimals = decimals
        self.infoTitle = infoTitle
        self.infoDescription = infoDescription
        self.infoIcon = infoIcon
        self.isDisabled = isDisabled
    }
    
    private var clampedValue: Binding<Double> {
        Binding<Double>(
            get: { value },
            set: {
                var newValue = $0
                if let step = step {
                    newValue = (newValue / step).rounded() * step
                }
                value = min(max(newValue, range.lowerBound), range.upperBound)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                InfoButton(
                    isPresented: $showInfo,
                    title: infoTitle,
                    description: infoDescription,
                    icon: infoIcon
                )
                Spacer()
                DoubleInputField(value: clampedValue, decimals: decimals)
                    .disabled(isDisabled)
            }
            Slider(value: clampedValue, in: range, step: step ?? 0.001)
                .disabled(isDisabled)
        }
    }
}

/// A standard configuration header with title and reset button.
struct ConfigurationHeader: View {
    let title: String
    let onReset: () -> Void
    let resetLabel: String
    
    init(title: String = "Configuration", resetLabel: String = "Reset to Defaults", onReset: @escaping () -> Void) {
        self.title = title
        self.resetLabel = resetLabel
        self.onReset = onReset
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .bold()
            Spacer()
            Button(resetLabel) {
                onReset()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
    }
}

/// A batch size picker with common DQN batch size options.
struct BatchSizePicker: View {
    @Binding var batchSize: Int
    let options: [Int]
    let isDisabled: Bool
    let infoDescription: String
    
    @State private var showInfo = false
    
    init(
        batchSize: Binding<Int>,
        options: [Int] = [32, 64, 128, 256],
        isDisabled: Bool = false,
        infoDescription: String = "Number of transitions sampled from replay buffer per update step."
    ) {
        self._batchSize = batchSize
        self.options = options
        self.isDisabled = isDisabled
        self.infoDescription = infoDescription
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Batch Size")
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                InfoButton(
                    isPresented: $showInfo,
                    title: "Batch Size",
                    description: infoDescription,
                    icon: "info.circle"
                )
                Spacer()
                Text("\(batchSize)")
                    .monospacedDigit()
            }
            Picker("", selection: $batchSize) {
                ForEach(options, id: \.self) { size in
                    Text("\(size)").tag(size)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isDisabled)
        }
    }
}

/// Shared DQN hyperparameters section used across DQN-based environments.
struct DQNHyperparametersSection: View {
    @Binding var learningRate: Double
    let learningRateRange: ClosedRange<Double>
    @Binding var gamma: Double
    @Binding var epsilon: Double
    @Binding var epsilonDecaySteps: Int
    @Binding var epsilonMin: Double
    @Binding var tau: Double
    @Binding var batchSize: Int
    let isTraining: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hyperparameters (DQN)")
                .font(.headline)
            
            let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
            LazyVGrid(columns: columns, spacing: 12) {
                Group {
                    HyperparameterSlider(
                        title: "Learning Rate",
                        value: $learningRate,
                        range: learningRateRange,
                        step: 0.0001,
                        decimals: learningRateRange.lowerBound < 0.001 ? 5 : 4,
                        infoTitle: "Learning Rate",
                        infoDescription: "Step size for network weight updates.",
                        infoIcon: "bolt.horizontal",
                        isDisabled: isTraining
                    )
                    
                    HyperparameterSlider(
                        title: "Gamma (Discount)",
                        value: $gamma,
                        range: 0.8...0.999,
                        step: 0.001,
                        decimals: 3,
                        infoTitle: "Gamma",
                        infoDescription: "Discount factor for future rewards.",
                        infoIcon: "clock.arrow.circlepath",
                        isDisabled: isTraining
                    )
                    
                    HyperparameterSlider(
                        title: "Epsilon (Exploration)",
                        value: $epsilon,
                        range: 0.0...1.0,
                        step: 0.01,
                        decimals: 2,
                        infoTitle: "Epsilon",
                        infoDescription: "Probability of random action.",
                        infoIcon: "die.face.5",
                        isDisabled: isTraining
                    )
                    
                    epsilonDecaySlider
                    
                    HyperparameterSlider(
                        title: "Epsilon Min",
                        value: $epsilonMin,
                        range: 0.0...1.0,
                        step: 0.001,
                        decimals: 3,
                        infoTitle: "Epsilon Min",
                        infoDescription: "Lower bound for exploration probability.",
                        infoIcon: "info.circle",
                        isDisabled: isTraining
                    )
                }
                
                Group {
                    HyperparameterSlider(
                        title: "Tau (Soft Update)",
                        value: $tau,
                        range: 0.001...0.1,
                        step: 0.001,
                        decimals: 3,
                        infoTitle: "Tau",
                        infoDescription: "Soft update coefficient.",
                        infoIcon: "arrow.triangle.2.circlepath",
                        isDisabled: isTraining
                    )
                    
                    BatchSizePicker(batchSize: $batchSize, isDisabled: isTraining)
                }
            }
        }
    }
    
    private var epsilonDecaySlider: some View {
        let minDecaySteps = 1_000.0
        let maxDecaySteps = 200_000.0
        let decayStepsBinding = Binding<Double>(
            get: { Double(epsilonDecaySteps) },
            set: {
                let clamped = min(maxDecaySteps, max(minDecaySteps, $0.rounded()))
                epsilonDecaySteps = Int(clamped)
            }
        )
        
        return HyperparameterSlider(
            title: "Epsilon Decay Steps",
            value: decayStepsBinding,
            range: minDecaySteps...maxDecaySteps,
            step: 1_000,
            decimals: 0,
            infoTitle: "Decay Schedule",
            infoDescription: "Time constant (in optimizer steps) for exponential epsilon decay.",
            infoIcon: "arrow.down.right.circle",
            isDisabled: isTraining
        )
    }
}

/// Shared advanced settings section for DQN-based environments.
struct DQNAdvancedSection: View {
    @Binding var useSeed: Bool
    @Binding var seed: Int
    @Binding var earlyStopEnabled: Bool
    @Binding var earlyStopWindow: Int
    @Binding var earlyStopRewardThreshold: Double
    @Binding var clipReward: Bool
    @Binding var clipRewardMin: Double
    @Binding var clipRewardMax: Double
    @Binding var gradClipNorm: Double
    let isTraining: Bool
    
    @State private var showSeedInfo = false
    @State private var showEarlyStopInfo = false
    @State private var showClipInfo = false
    @State private var showGradClipInfo = false
    
    var body: some View {
        DisclosureGroup("Advanced") {
            VStack(alignment: .leading, spacing: 12) {
                seedSection
                earlyStopSection
                clipRewardSection
                gradientClipSection
            }
            .padding(.top, 6)
        }
    }
    
    private var seedSection: some View {
        Group {
            HStack {
                Text("Use Seed")
                    .lineLimit(1)
                InfoButton(isPresented: $showSeedInfo, title: "Seed", description: "Enable deterministic initialization for reproducible runs.", icon: "info.circle")
                Spacer()
                Toggle("", isOn: $useSeed)
                    .labelsHidden()
                    .fixedSize()
                    .disabled(isTraining)
            }
            HStack {
                Text("Seed")
                Spacer()
                TextField("0", value: $seed, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .disabled(!useSeed || isTraining)
            }
        }
    }
    
    private var earlyStopSection: some View {
        Group {
            HStack {
                Text("Early Stop")
                    .lineLimit(1)
                InfoButton(isPresented: $showEarlyStopInfo, title: "Early Stop", description: "Automatically stop training when the moving average reward exceeds the threshold.", icon: "info.circle")
                Spacer()
                Toggle("", isOn: $earlyStopEnabled)
                    .labelsHidden()
                    .fixedSize()
                    .disabled(isTraining)
            }
            HStack {
                Text("Window (episodes)")
                Spacer()
                TextField("100", value: $earlyStopWindow, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .disabled(!earlyStopEnabled || isTraining)
            }
            HStack {
                Text("Threshold")
                Spacer()
                TextField("195", value: $earlyStopRewardThreshold, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .disabled(!earlyStopEnabled || isTraining)
            }
        }
    }
    
    private var clipRewardSection: some View {
        Group {
            HStack {
                Text("Clip Reward")
                    .lineLimit(1)
                InfoButton(isPresented: $showClipInfo, title: "Clip Reward", description: "Clamp rewards into a fixed range to improve stability.", icon: "info.circle")
                Spacer()
                Toggle("", isOn: $clipReward)
                    .labelsHidden()
                    .fixedSize()
                    .disabled(isTraining)
            }
            HStack {
                Text("Min")
                Spacer()
                TextField("-1.0", value: $clipRewardMin, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }.disabled(!clipReward || isTraining)
            HStack {
                Text("Max")
                Spacer()
                TextField("1.0", value: $clipRewardMax, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }.disabled(!clipReward || isTraining)
        }
    }
    
    private var gradientClipSection: some View {
        HyperparameterSlider(
            title: "Grad Clip Norm",
            value: $gradClipNorm,
            range: 1...1000,
            step: 1,
            decimals: 0,
            infoTitle: "Gradient Clipping",
            infoDescription: "Clamp the global gradient norm to this maximum to prevent exploding gradients.",
            infoIcon: "info.circle",
            isDisabled: isTraining
        )
    }
}

/// Shared SAC hyperparameters section used across SAC-based environments.
struct SACHyperparametersSection: View {
    @Binding var learningRate: Double
    let learningRateRange: ClosedRange<Double>
    @Binding var gamma: Double
    @Binding var tau: Double
    let tauRange: ClosedRange<Double>
    @Binding var alpha: Double
    @Binding var batchSize: Int
    let batchSizeOptions: [Int]
    let isTraining: Bool
    
    // Optional warmup and buffer (for environments that use them)
    @Binding var warmupSteps: Int
    let showWarmup: Bool
    @Binding var bufferSize: Int
    let showBuffer: Bool
    
    init(
        learningRate: Binding<Double>,
        learningRateRange: ClosedRange<Double> = 0.00001...0.01,
        gamma: Binding<Double>,
        tau: Binding<Double>,
        tauRange: ClosedRange<Double> = 0.001...0.1,
        alpha: Binding<Double>,
        batchSize: Binding<Int>,
        batchSizeOptions: [Int] = [64, 128, 256, 512],
        isTraining: Bool,
        warmupSteps: Binding<Int> = .constant(0),
        showWarmup: Bool = false,
        bufferSize: Binding<Int> = .constant(0),
        showBuffer: Bool = false
    ) {
        self._learningRate = learningRate
        self.learningRateRange = learningRateRange
        self._gamma = gamma
        self._tau = tau
        self.tauRange = tauRange
        self._alpha = alpha
        self._batchSize = batchSize
        self.batchSizeOptions = batchSizeOptions
        self.isTraining = isTraining
        self._warmupSteps = warmupSteps
        self.showWarmup = showWarmup
        self._bufferSize = bufferSize
        self.showBuffer = showBuffer
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hyperparameters (SAC)")
                .font(.headline)
            
            let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
            LazyVGrid(columns: columns, spacing: 12) {
                Group {
                    HyperparameterSlider(
                        title: "Learning Rate",
                        value: $learningRate,
                        range: learningRateRange,
                        step: 0.00001,
                        decimals: 5,
                        infoTitle: "Learning Rate",
                        infoDescription: "Step size for network weight updates.",
                        infoIcon: "bolt.horizontal",
                        isDisabled: isTraining
                    )
                    
                    HyperparameterSlider(
                        title: "Gamma (Discount)",
                        value: $gamma,
                        range: 0.9...0.9999,
                        step: 0.0001,
                        decimals: 4,
                        infoTitle: "Gamma",
                        infoDescription: "Discount factor for future rewards.",
                        infoIcon: "clock.arrow.circlepath",
                        isDisabled: isTraining
                    )
                    
                    HyperparameterSlider(
                        title: "Tau (Soft Update)",
                        value: $tau,
                        range: tauRange,
                        step: 0.001,
                        decimals: 3,
                        infoTitle: "Tau",
                        infoDescription: "Soft update coefficient for target networks.",
                        infoIcon: "arrow.triangle.2.circlepath",
                        isDisabled: isTraining
                    )
                    
                    HyperparameterSlider(
                        title: "Alpha (Entropy)",
                        value: $alpha,
                        range: 0.01...1.0,
                        step: 0.01,
                        decimals: 2,
                        infoTitle: "Alpha",
                        infoDescription: "Entropy regularization coefficient. Controls exploration-exploitation tradeoff.",
                        infoIcon: "waveform",
                        isDisabled: isTraining
                    )
                }
                
                Group {
                    BatchSizePicker(batchSize: $batchSize, options: batchSizeOptions, isDisabled: isTraining)
                    
                    if showWarmup {
                        warmupSlider
                    }
                    
                    if showBuffer {
                        bufferSlider
                    }
                }
            }
        }
    }
    
    private var warmupSlider: some View {
        let warmupBinding = Binding<Double>(
            get: { Double(warmupSteps) },
            set: { warmupSteps = max(0, Int($0.rounded())) }
        )
        
        return HyperparameterSlider(
            title: "Warmup Steps",
            value: warmupBinding,
            range: 0...50_000,
            step: 100,
            decimals: 0,
            infoTitle: "Warmup Steps",
            infoDescription: "Number of random action steps before training begins.",
            infoIcon: "flame",
            isDisabled: isTraining
        )
    }
    
    private var bufferSlider: some View {
        let bufferBinding = Binding<Double>(
            get: { Double(bufferSize) },
            set: { bufferSize = max(10_000, Int($0.rounded())) }
        )
        
        return HyperparameterSlider(
            title: "Buffer Size",
            value: bufferBinding,
            range: 10_000...1_000_000,
            step: 10_000,
            decimals: 0,
            infoTitle: "Buffer Size",
            infoDescription: "Replay buffer capacity.",
            infoIcon: "memorychip",
            isDisabled: isTraining
        )
    }
}

/// Simple seed section for SAC advanced settings.
struct SeedSection: View {
    @Binding var useSeed: Bool
    @Binding var seed: Int
    let isTraining: Bool
    
    @State private var showSeedInfo = false
    
    var body: some View {
        DisclosureGroup("Advanced") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Use Seed")
                        .lineLimit(1)
                    InfoButton(isPresented: $showSeedInfo, title: "Seed", description: "Enable deterministic initialization for reproducible runs.", icon: "info.circle")
                    Spacer()
                    Toggle("", isOn: $useSeed)
                        .labelsHidden()
                        .fixedSize()
                        .disabled(isTraining)
                }
                
                if useSeed {
                    let seedBinding = Binding<Double>(
                        get: { Double(seed) },
                        set: { seed = Int($0.rounded()) }
                    )
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Seed Value")
                            Spacer()
                            DoubleInputField(value: seedBinding, decimals: 0)
                                .disabled(isTraining)
                        }
                        Slider(value: seedBinding, in: 0...1000, step: 1)
                            .disabled(isTraining)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}


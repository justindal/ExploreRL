//
//  HyperparameterDefinitions.swift
//  ExploreRL
//

import Foundation

struct HyperparameterDefinition: Identifiable {
    let id: String
    let label: String
    let type: HyperparameterType
    let description: String?

    enum HyperparameterType {
        case double(default: Double, range: ClosedRange<Double>?, step: Double?)
        case float(default: Float, range: ClosedRange<Float>?, step: Float?)
        case int(default: Int, range: ClosedRange<Int>?)
        case bool(default: Bool)
        case string(default: String, options: [String]?)
    }
}

enum HyperparameterConfig {
    static let tabular: [HyperparameterDefinition] = [
        HyperparameterDefinition(
            id: "learningRate",
            label: "Learning Rate (α)",
            type: .double(default: 0.5, range: 0.01...1.0, step: nil),
            description: "Step size for Q-value updates (higher = faster learning)"
        ),
        HyperparameterDefinition(
            id: "gamma",
            label: "Discount Factor (γ)",
            type: .double(default: 0.95, range: 0.5...1.0, step: 0.01),
            description: "How much to value future rewards"
        ),
        HyperparameterDefinition(
            id: "epsilon",
            label: "Epsilon (ε)",
            type: .double(default: 1.0, range: 0.0...1.0, step: nil),
            description: "Starting exploration rate"
        ),
        HyperparameterDefinition(
            id: "epsilonDecay",
            label: "Epsilon Decay",
            type: .double(default: 0.995, range: 0.9...1.0, step: nil),
            description: "Multiplicative decay applied per episode"
        ),
        HyperparameterDefinition(
            id: "minEpsilon",
            label: "Min Epsilon",
            type: .double(default: 0.01, range: 0.0...0.5, step: nil),
            description: "Minimum exploration rate"
        )
    ]

    static let dqn: [HyperparameterDefinition] = [
        HyperparameterDefinition(
            id: "learningRate",
            label: "Learning Rate",
            type: .float(default: 1e-4, range: 1e-6...1e-2, step: nil),
            description: "Neural network learning rate"
        ),
        HyperparameterDefinition(
            id: "learningRateSchedule",
            label: "LR Schedule",
            type: .string(
                default: "constant",
                options: ["constant", "linear", "exponential", "step", "cosine"]
            ),
            description: "Learning rate schedule type"
        ),
        HyperparameterDefinition(
            id: "learningRateFinal",
            label: "LR Final",
            type: .float(default: 0.0, range: 0.0...1e-2, step: nil),
            description: "Final learning rate for linear schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateDecayRate",
            label: "LR Decay Rate",
            type: .float(default: 0.99, range: 0.8...1.0, step: nil),
            description: "Decay rate for exponential schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateMinValue",
            label: "LR Min",
            type: .float(default: 0.0, range: 0.0...1e-2, step: nil),
            description: "Minimum learning rate for cosine schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateMilestones",
            label: "LR Milestones",
            type: .string(default: "0.5,0.75", options: nil),
            description: "Comma-separated progress milestones for step schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateGamma",
            label: "LR Gamma",
            type: .float(default: 0.1, range: 0.01...1.0, step: nil),
            description: "Step schedule decay factor"
        ),
        HyperparameterDefinition(
            id: "warmupEnabled",
            label: "Warmup",
            type: .bool(default: false),
            description: "Enable learning rate warmup"
        ),
        HyperparameterDefinition(
            id: "warmupFraction",
            label: "Warmup Fraction",
            type: .double(default: 0.05, range: 0.0...0.5, step: 0.01),
            description: "Fraction of training for warmup"
        ),
        HyperparameterDefinition(
            id: "warmupInitialValue",
            label: "Warmup Initial",
            type: .float(default: 0.0, range: 0.0...1e-2, step: nil),
            description: "Initial learning rate during warmup"
        ),
        HyperparameterDefinition(
            id: "gamma",
            label: "Discount Factor (γ)",
            type: .double(default: 0.99, range: 0.0...1.0, step: 0.01),
            description: "How much to value future rewards"
        ),
        HyperparameterDefinition(
            id: "batchSize",
            label: "Batch Size",
            type: .int(default: 32, range: 16...512),
            description: "Samples per training update"
        ),
        HyperparameterDefinition(
            id: "bufferSize",
            label: "Buffer Size",
            type: .int(default: 1_000_000, range: 10_000...1_000_000),
            description: "Replay buffer capacity"
        ),
        HyperparameterDefinition(
            id: "learningStarts",
            label: "Learning Starts",
            type: .int(default: 1_000, range: 100...50_000),
            description: "Steps before training begins"
        ),
        HyperparameterDefinition(
            id: "trainFrequency",
            label: "Train Frequency",
            type: .int(default: 4, range: 1...1000),
            description: "Steps or episodes between training updates"
        ),
        HyperparameterDefinition(
            id: "trainFrequencyUnit",
            label: "Train Frequency Unit",
            type: .string(default: "step", options: ["step", "episode"]),
            description: "Update schedule based on steps or episodes"
        ),
        HyperparameterDefinition(
            id: "gradientSteps",
            label: "Gradient Steps",
            type: .int(default: 1, range: -1...100),
            description: "Number of gradient steps per update (-1 uses collected steps)"
        ),
        HyperparameterDefinition(
            id: "gradientStepsMode",
            label: "Gradient Steps Mode",
            type: .string(default: "fixed", options: ["fixed", "asCollectedSteps"]),
            description: "Fixed steps or match collected steps"
        ),
        HyperparameterDefinition(
            id: "targetUpdateInterval",
            label: "Target Update Interval",
            type: .int(default: 10_000, range: 100...50_000),
            description: "Steps between target network updates"
        ),
        HyperparameterDefinition(
            id: "tau",
            label: "Soft Update (τ)",
            type: .double(default: 1.0, range: 0.0...1.0, step: 0.01),
            description: "Target network soft update coefficient"
        ),
        HyperparameterDefinition(
            id: "maxGradNorm",
            label: "Max Grad Norm",
            type: .double(default: 10.0, range: 0.0...100.0, step: 0.5),
            description: "Gradient clipping threshold (0 disables)"
        ),
        HyperparameterDefinition(
            id: "explorationFraction",
            label: "Exploration Fraction",
            type: .double(default: 0.2, range: 0.01...1.0, step: 0.05),
            description: "Fraction of training for epsilon decay"
        ),
        HyperparameterDefinition(
            id: "explorationInitialEps",
            label: "Initial Epsilon",
            type: .double(default: 1.0, range: 0.0...1.0, step: 0.1),
            description: "Starting exploration rate"
        ),
        HyperparameterDefinition(
            id: "explorationFinalEps",
            label: "Final Epsilon",
            type: .double(default: 0.05, range: 0.0...1.0, step: 0.01),
            description: "Minimum exploration rate"
        ),
        HyperparameterDefinition(
            id: "netArch",
            label: "Network Layers",
            type: .string(default: "64,64", options: nil),
            description: "Comma-separated hidden layer sizes"
        ),
        HyperparameterDefinition(
            id: "activation",
            label: "Activation",
            type: .string(default: "relu", options: ["relu"]),
            description: "Hidden layer activation"
        ),
        HyperparameterDefinition(
            id: "normalizeImages",
            label: "Normalize Images",
            type: .bool(default: true),
            description: "Normalize image observations"
        ),
        HyperparameterDefinition(
            id: "optimizerBeta1",
            label: "Adam Beta1",
            type: .float(default: 0.9, range: 0.0...0.999, step: nil),
            description: "Optimizer beta1"
        ),
        HyperparameterDefinition(
            id: "optimizerBeta2",
            label: "Adam Beta2",
            type: .float(default: 0.999, range: 0.0...0.999, step: nil),
            description: "Optimizer beta2"
        ),
        HyperparameterDefinition(
            id: "optimizerEps",
            label: "Adam Epsilon",
            type: .float(default: 1e-8, range: 1e-12...1e-4, step: nil),
            description: "Optimizer epsilon"
        ),
        HyperparameterDefinition(
            id: "optimizeMemoryUsage",
            label: "Optimize Memory Usage",
            type: .bool(default: false),
            description: "Reduce replay buffer memory usage"
        ),
        HyperparameterDefinition(
            id: "handleTimeoutTermination",
            label: "Handle Timeout Termination",
            type: .bool(default: true),
            description: "Treat time limits as terminal states"
        )
    ]

    static let sac: [HyperparameterDefinition] = [
        HyperparameterDefinition(
            id: "learningRate",
            label: "Learning Rate",
            type: .float(default: 3e-4, range: 1e-6...1e-2, step: nil),
            description: "Neural network learning rate"
        ),
        HyperparameterDefinition(
            id: "learningRateSchedule",
            label: "LR Schedule",
            type: .string(
                default: "constant",
                options: ["constant", "linear", "exponential", "step", "cosine"]
            ),
            description: "Learning rate schedule type"
        ),
        HyperparameterDefinition(
            id: "learningRateFinal",
            label: "LR Final",
            type: .float(default: 0.0, range: 0.0...1e-2, step: nil),
            description: "Final learning rate for linear schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateDecayRate",
            label: "LR Decay Rate",
            type: .float(default: 0.99, range: 0.8...1.0, step: nil),
            description: "Decay rate for exponential schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateMinValue",
            label: "LR Min",
            type: .float(default: 0.0, range: 0.0...1e-2, step: nil),
            description: "Minimum learning rate for cosine schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateMilestones",
            label: "LR Milestones",
            type: .string(default: "0.5,0.75", options: nil),
            description: "Comma-separated progress milestones for step schedule"
        ),
        HyperparameterDefinition(
            id: "learningRateGamma",
            label: "LR Gamma",
            type: .float(default: 0.1, range: 0.01...1.0, step: nil),
            description: "Step schedule decay factor"
        ),
        HyperparameterDefinition(
            id: "warmupEnabled",
            label: "Warmup",
            type: .bool(default: false),
            description: "Enable learning rate warmup"
        ),
        HyperparameterDefinition(
            id: "warmupFraction",
            label: "Warmup Fraction",
            type: .double(default: 0.05, range: 0.0...0.5, step: 0.01),
            description: "Fraction of training for warmup"
        ),
        HyperparameterDefinition(
            id: "warmupInitialValue",
            label: "Warmup Initial",
            type: .float(default: 0.0, range: 0.0...1e-2, step: nil),
            description: "Initial learning rate during warmup"
        ),
        HyperparameterDefinition(
            id: "gamma",
            label: "Discount Factor (γ)",
            type: .double(default: 0.99, range: 0.0...1.0, step: 0.01),
            description: "How much to value future rewards"
        ),
        HyperparameterDefinition(
            id: "batchSize",
            label: "Batch Size",
            type: .int(default: 256, range: 32...1024),
            description: "Samples per training update"
        ),
        HyperparameterDefinition(
            id: "bufferSize",
            label: "Buffer Size",
            type: .int(default: 1_000_000, range: 10_000...1_000_000),
            description: "Replay buffer capacity"
        ),
        HyperparameterDefinition(
            id: "learningStarts",
            label: "Learning Starts",
            type: .int(default: 100, range: 100...50_000),
            description: "Steps before training begins"
        ),
        HyperparameterDefinition(
            id: "trainFrequency",
            label: "Train Frequency",
            type: .int(default: 1, range: 1...1000),
            description: "Steps or episodes between training updates"
        ),
        HyperparameterDefinition(
            id: "trainFrequencyUnit",
            label: "Train Frequency Unit",
            type: .string(default: "step", options: ["step", "episode"]),
            description: "Update schedule based on steps or episodes"
        ),
        HyperparameterDefinition(
            id: "gradientSteps",
            label: "Gradient Steps",
            type: .int(default: 1, range: -1...100),
            description: "Number of gradient steps per update (-1 uses collected steps)"
        ),
        HyperparameterDefinition(
            id: "gradientStepsMode",
            label: "Gradient Steps Mode",
            type: .string(default: "fixed", options: ["fixed", "asCollectedSteps"]),
            description: "Fixed steps or match collected steps"
        ),
        HyperparameterDefinition(
            id: "tau",
            label: "Soft Update (τ)",
            type: .double(default: 0.005, range: 0.001...0.1, step: 0.001),
            description: "Target network soft update coefficient"
        ),
        HyperparameterDefinition(
            id: "targetUpdateInterval",
            label: "Target Update Interval",
            type: .int(default: 1, range: 1...10_000),
            description: "Gradient steps between target updates"
        ),
        HyperparameterDefinition(
            id: "autoEntropyTuning",
            label: "Auto Entropy Tuning",
            type: .bool(default: true),
            description: "Automatically tune entropy coefficient"
        ),
        HyperparameterDefinition(
            id: "autoEntropyInit",
            label: "Auto Entropy Init",
            type: .float(default: 1.0, range: 0.01...10.0, step: nil),
            description: "Initial entropy coefficient for auto tuning"
        ),
        HyperparameterDefinition(
            id: "fixedEntCoef",
            label: "Fixed Entropy Coef",
            type: .float(default: 0.2, range: 0.0...2.0, step: nil),
            description: "Entropy coefficient when auto tuning is off"
        ),
        HyperparameterDefinition(
            id: "useTargetEntropy",
            label: "Use Target Entropy",
            type: .bool(default: false),
            description: "Override default target entropy"
        ),
        HyperparameterDefinition(
            id: "targetEntropy",
            label: "Target Entropy",
            type: .float(default: 0.0, range: -20.0...0.0, step: nil),
            description: "Target entropy value"
        ),
        HyperparameterDefinition(
            id: "netArch",
            label: "Actor Layers",
            type: .string(default: "256,256", options: nil),
            description: "Comma-separated hidden layer sizes"
        ),
        HyperparameterDefinition(
            id: "useSeparateNetworks",
            label: "Separate Actor/Critic",
            type: .bool(default: false),
            description: "Use different actor and critic architectures"
        ),
        HyperparameterDefinition(
            id: "criticNetArch",
            label: "Critic Layers",
            type: .string(default: "256,256", options: nil),
            description: "Comma-separated critic hidden sizes"
        ),
        HyperparameterDefinition(
            id: "nCritics",
            label: "Number of Critics",
            type: .int(default: 2, range: 1...4),
            description: "Number of Q-networks"
        ),
        HyperparameterDefinition(
            id: "shareFeaturesExtractor",
            label: "Share Features Extractor",
            type: .bool(default: false),
            description: "Share extractor between actor and critic"
        ),
        HyperparameterDefinition(
            id: "activation",
            label: "Actor Activation",
            type: .string(default: "relu", options: ["relu"]),
            description: "Hidden layer activation"
        ),
        HyperparameterDefinition(
            id: "normalizeImages",
            label: "Actor Normalize Images",
            type: .bool(default: true),
            description: "Normalize image observations"
        ),
        HyperparameterDefinition(
            id: "criticActivation",
            label: "Critic Activation",
            type: .string(default: "relu", options: ["relu"]),
            description: "Critic hidden layer activation"
        ),
        HyperparameterDefinition(
            id: "criticNormalizeImages",
            label: "Critic Normalize Images",
            type: .bool(default: true),
            description: "Normalize critic image observations"
        ),
        HyperparameterDefinition(
            id: "useSDE",
            label: "Use SDE",
            type: .bool(default: false),
            description: "State-dependent exploration"
        ),
        HyperparameterDefinition(
            id: "useSDEAtWarmup",
            label: "Use SDE At Warmup",
            type: .bool(default: false),
            description: "Apply SDE during warmup"
        ),
        HyperparameterDefinition(
            id: "sdeSampleFreq",
            label: "SDE Sample Freq",
            type: .int(default: -1, range: -1...1000),
            description: "SDE noise resampling frequency"
        ),
        HyperparameterDefinition(
            id: "logStdInit",
            label: "Log Std Init",
            type: .float(default: -3.0, range: -20.0...2.0, step: nil),
            description: "Initial log standard deviation"
        ),
        HyperparameterDefinition(
            id: "fullStd",
            label: "Full Std",
            type: .bool(default: true),
            description: "Use full covariance for SDE"
        ),
        HyperparameterDefinition(
            id: "clipMean",
            label: "Clip Mean",
            type: .float(default: 2.0, range: 0.0...10.0, step: nil),
            description: "Mean clipping range"
        ),
        HyperparameterDefinition(
            id: "optimizeMemoryUsage",
            label: "Optimize Memory Usage",
            type: .bool(default: false),
            description: "Reduce replay buffer memory usage"
        ),
        HyperparameterDefinition(
            id: "handleTimeoutTermination",
            label: "Handle Timeout Termination",
            type: .bool(default: true),
            description: "Treat time limits as terminal states"
        ),
        HyperparameterDefinition(
            id: "optimizerActorBeta1",
            label: "Actor Adam Beta1",
            type: .float(default: 0.9, range: 0.0...0.999, step: nil),
            description: "Actor optimizer beta1"
        ),
        HyperparameterDefinition(
            id: "optimizerActorBeta2",
            label: "Actor Adam Beta2",
            type: .float(default: 0.999, range: 0.0...0.999, step: nil),
            description: "Actor optimizer beta2"
        ),
        HyperparameterDefinition(
            id: "optimizerActorEps",
            label: "Actor Adam Eps",
            type: .float(default: 1e-8, range: 1e-12...1e-4, step: nil),
            description: "Actor optimizer epsilon"
        ),
        HyperparameterDefinition(
            id: "optimizerCriticBeta1",
            label: "Critic Adam Beta1",
            type: .float(default: 0.9, range: 0.0...0.999, step: nil),
            description: "Critic optimizer beta1"
        ),
        HyperparameterDefinition(
            id: "optimizerCriticBeta2",
            label: "Critic Adam Beta2",
            type: .float(default: 0.999, range: 0.0...0.999, step: nil),
            description: "Critic optimizer beta2"
        ),
        HyperparameterDefinition(
            id: "optimizerCriticEps",
            label: "Critic Adam Eps",
            type: .float(default: 1e-8, range: 1e-12...1e-4, step: nil),
            description: "Critic optimizer epsilon"
        ),
        HyperparameterDefinition(
            id: "optimizerEntropyBeta1",
            label: "Entropy Adam Beta1",
            type: .float(default: 0.9, range: 0.0...0.999, step: nil),
            description: "Entropy optimizer beta1"
        ),
        HyperparameterDefinition(
            id: "optimizerEntropyBeta2",
            label: "Entropy Adam Beta2",
            type: .float(default: 0.999, range: 0.0...0.999, step: nil),
            description: "Entropy optimizer beta2"
        ),
        HyperparameterDefinition(
            id: "optimizerEntropyEps",
            label: "Entropy Adam Eps",
            type: .float(default: 1e-8, range: 1e-12...1e-4, step: nil),
            description: "Entropy optimizer epsilon"
        )
    ]

    static func definitions(for algorithm: AlgorithmType) -> [HyperparameterDefinition] {
        switch algorithm {
        case .qLearning, .sarsa:
            return tabular
        case .dqn:
            return dqn
        case .sac:
            return sac
        }
    }
}

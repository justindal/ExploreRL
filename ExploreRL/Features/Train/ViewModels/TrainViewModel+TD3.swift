import Foundation
import Gymnazo

extension TrainViewModel {
    func runTD3Training(
        id: String,
        config: TrainingConfig,
        totalTimesteps: Int,
        renderEnabled: Bool,
        renderFPS: Int,
        isResuming: Bool = false,
        accumulator: TrainingAccumulator
    ) async throws {
        guard let env = env(for: id) else {
            throw TrainError.environmentNotLoaded
        }

        let td3 = td3Algorithm(for: id, env: env, config: config)

        if !isResuming {
            updateTrainingState(for: id) { s in
                s.currentTimestep = 0
            }
        }

        let callbacks = makeCallbacks(
            for: id,
            accumulator: accumulator,
            renderEnabled: renderEnabled,
            renderFPS: renderFPS,
            trackExplorationRate: false,
            onFlush: { [weak self] in self?.flushAccumulator(for: id) }
        )

        try await td3.learn(
            totalTimesteps: totalTimesteps,
            callbacks: callbacks,
            resetProgress: !isResuming
        )

        if let finalEnv = td3.takeEnv() {
            envStates[id] = .loaded(finalEnv)
        }
    }

    func td3Algorithm(for id: String, env: any Env, config: TrainingConfig) -> TD3 {
        let resetOptions = envResetOptions(for: id)
        let resetSeed = envResetSeed(for: id)
        let configuredEnv = ConfiguredEnv(
            base: env,
            resetSeed: resetSeed,
            resetOptions: resetOptions
        )

        if let existing = td3Algorithms[id] {
            existing.setEnv(configuredEnv)
            return existing
        }

        let td3Settings = sanitizedTD3Hyperparameters(config.td3)

        let trainFrequency = TrainFrequency(
            frequency: max(1, td3Settings.trainFrequency),
            unit: trainFrequencyUnit(from: td3Settings.trainFrequencyUnit)
        )
        let resolvedGradientSteps = gradientSteps(
            mode: td3Settings.gradientStepsMode,
            count: td3Settings.gradientSteps
        )

        let offPolicyConfig = OffPolicyConfig(
            bufferSize: td3Settings.bufferSize,
            learningStarts: td3Settings.learningStarts,
            batchSize: td3Settings.batchSize,
            tau: td3Settings.tau,
            gamma: td3Settings.gamma,
            trainFrequency: trainFrequency,
            gradientSteps: resolvedGradientSteps,
            targetUpdateInterval: 1,
            optimizeMemoryUsage: td3Settings.optimizeMemoryUsage,
            handleTimeoutTermination: td3Settings.handleTimeoutTermination,
            useSDEAtWarmup: false,
            sdeSampleFreq: -1,
            sdeSupported: false
        )

        let policyConfig = TD3PolicyConfig(
            netArch: .shared(td3Settings.netArch),
            featuresExtractor: .auto,
            activation: activationConfig(from: td3Settings.activation),
            normalizeImages: td3Settings.normalizeImages,
            nCritics: td3Settings.nCritics,
            shareFeaturesExtractor: td3Settings.shareFeaturesExtractor,
            actorOptimizer: .adam(
                beta1: td3Settings.optimizerActorBeta1,
                beta2: td3Settings.optimizerActorBeta2,
                eps: td3Settings.optimizerActorEps
            ),
            criticOptimizer: .adam(
                beta1: td3Settings.optimizerCriticBeta1,
                beta2: td3Settings.optimizerCriticBeta2,
                eps: td3Settings.optimizerCriticEps
            )
        )

        let algorithmConfig = TD3AlgorithmConfig(
            policyDelay: td3Settings.policyDelay,
            targetPolicyNoise: td3Settings.targetPolicyNoise,
            targetNoiseClip: td3Settings.targetNoiseClip,
            actionNoise: td3ActionNoise(from: td3Settings)
        )

        let learningRate = learningRateSchedule(
            schedule: td3Settings.learningRateSchedule,
            initial: Double(td3Settings.learningRate),
            final: Double(td3Settings.learningRateFinal),
            decayRate: Double(td3Settings.learningRateDecayRate),
            minValue: Double(td3Settings.learningRateMinValue),
            milestones: parseMilestones(td3Settings.learningRateMilestones),
            gamma: Double(td3Settings.learningRateGamma),
            warmupEnabled: td3Settings.warmupEnabled,
            warmupFraction: td3Settings.warmupFraction,
            warmupInitial: Double(td3Settings.warmupInitialValue)
        )

        let td3 = TD3(
            observationSpace: configuredEnv.observationSpace,
            actionSpace: configuredEnv.actionSpace,
            learningRate: learningRate,
            policyConfig: policyConfig,
            algorithmConfig: algorithmConfig,
            config: offPolicyConfig,
            seed: config.seedValue
        )
        td3.setEnv(configuredEnv)

        td3Algorithms[id] = td3
        return td3
    }

    private func sanitizedTD3Hyperparameters(_ values: TD3Hyperparameters) -> TD3Hyperparameters {
        var output = values
        output.learningRate = max(output.learningRate, 1e-12)
        output.learningRateFinal = max(output.learningRateFinal, 0.0)
        output.learningRateDecayRate = max(output.learningRateDecayRate, 1e-6)
        output.learningRateMinValue = max(output.learningRateMinValue, 0.0)
        output.learningRateGamma = max(output.learningRateGamma, 1e-6)
        output.warmupFraction = clamp(output.warmupFraction, min: 0.0, max: 1.0)
        output.warmupInitialValue = max(output.warmupInitialValue, 0.0)
        output.bufferSize = max(1, output.bufferSize)
        output.batchSize = max(1, output.batchSize)
        output.learningStarts = max(0, output.learningStarts)
        output.gamma = clamp(output.gamma, min: 0.0, max: 1.0)
        output.tau = clamp(output.tau, min: 0.0, max: 1.0)
        output.trainFrequency = max(1, output.trainFrequency)
        output.gradientSteps = output.gradientSteps == -1 ? -1 : max(1, output.gradientSteps)
        output.policyDelay = max(1, output.policyDelay)
        output.targetPolicyNoise = max(output.targetPolicyNoise, 0.0)
        output.targetNoiseClip = max(output.targetNoiseClip, 0.0)
        output.actionNoiseType = output.actionNoiseType.lowercased()
        if !["none", "normal", "ou", "ornsteinuhlenbeck", "ornstein-uhlenbeck"].contains(output.actionNoiseType) {
            output.actionNoiseType = "none"
        }
        output.actionNoiseStd = max(output.actionNoiseStd, 0.0)
        output.ouTheta = max(output.ouTheta, 0.0)
        output.ouDt = max(output.ouDt, 1e-9)
        output.netArch = output.netArch.filter { $0 > 0 }
        if output.netArch.isEmpty {
            output.netArch = [400, 300]
        }
        output.nCritics = max(1, output.nCritics)
        output.optimizerActorBeta1 = clamp(output.optimizerActorBeta1, min: 0.0, max: 0.999_999)
        output.optimizerActorBeta2 = clamp(output.optimizerActorBeta2, min: 0.0, max: 0.999_999)
        output.optimizerActorEps = max(output.optimizerActorEps, 1e-12)
        output.optimizerCriticBeta1 = clamp(output.optimizerCriticBeta1, min: 0.0, max: 0.999_999)
        output.optimizerCriticBeta2 = clamp(output.optimizerCriticBeta2, min: 0.0, max: 0.999_999)
        output.optimizerCriticEps = max(output.optimizerCriticEps, 1e-12)
        if output.optimizeMemoryUsage && output.handleTimeoutTermination {
            output.optimizeMemoryUsage = false
        }
        return output
    }

    private func td3ActionNoise(from settings: TD3Hyperparameters) -> TD3ActionNoiseConfig? {
        switch settings.actionNoiseType.lowercased() {
        case "normal":
            return settings.actionNoiseStd > 0 ? .normal(std: settings.actionNoiseStd) : nil
        case "ou", "ornsteinuhlenbeck", "ornstein-uhlenbeck":
            guard settings.actionNoiseStd > 0 else { return nil }
            return .ornsteinUhlenbeck(
                std: settings.actionNoiseStd,
                theta: settings.ouTheta,
                dt: settings.ouDt,
                initialNoise: settings.ouInitialNoise
            )
        default:
            return nil
        }
    }
}

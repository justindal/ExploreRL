//
//  TrainViewModel+Training.swift
//  ExploreRL
//

import Foundation
import Gymnazo

extension TrainViewModel {

    func startTraining(for id: String) {
        guard trainingState(for: id).status != .training else { return }
        if trainingState(for: id).status == .paused {
            resumeTraining(for: id)
            return
        }

        guard let env = env(for: id) else {
            updateTrainingState(for: id) {
                $0.status = .failed("Environment not loaded")
            }
            return
        }

        let config = trainingConfig(for: id)
        let available = availableAlgorithms(for: env)

        guard available.contains(config.algorithm) else {
            updateTrainingState(for: id) {
                $0.status = .failed(
                    "Algorithm not compatible with this environment"
                )
            }
            return
        }

        updateTrainingState(for: id) { state in
            state.status = .training
            if state.currentTimestep == 0 {
                state.reset()
                state.status = .training
            }
        }

        if trainingTimings[id] == nil || trainingState(for: id).currentTimestep == 0 {
            trainingTimings[id] = TrainingTiming(startedAt: .now)
        }

        let accumulator = TrainingAccumulator()
        accumulators[id] = accumulator
        startFlushLoop(for: id)

        trainingTasks[id] = Task { [weak self] in
            await self?.runTraining(
                for: id,
                config: config,
                accumulator: accumulator,
                isResuming: false
            )
        }
    }

    func pauseTraining(for id: String) {
        Task { await tabularAgents[id]?.stop() }
        Task { await dqnAlgorithms[id]?.stop() }
        Task { await sacAlgorithms[id]?.stop() }
        trainingTimings[id]?.pause(at: .now)
        flushAccumulator(for: id)
        stopFlushLoop(for: id)
        updateTrainingState(for: id) { $0.status = .paused }
    }

    func resumeTraining(for id: String) {
        guard trainingState(for: id).status == .paused else { return }
        updateTrainingState(for: id) { $0.status = .training }

        if trainingTimings[id] == nil {
            trainingTimings[id] = TrainingTiming(startedAt: .now)
        } else {
            trainingTimings[id]?.resume(at: .now)
        }

        let accumulator = accumulators[id] ?? TrainingAccumulator()
        accumulators[id] = accumulator
        startFlushLoop(for: id)

        let config = trainingConfig(for: id)
        trainingTasks[id] = Task { [weak self] in
            await self?.runTraining(
                for: id,
                config: config,
                accumulator: accumulator,
                isResuming: true
            )
        }
    }

    @MainActor
    func resetTraining(for id: String) async {
        Task { await tabularAgents[id]?.stop() }
        Task { await dqnAlgorithms[id]?.stop() }
        Task { await sacAlgorithms[id]?.stop() }
        trainingTasks[id]?.cancel()
        trainingTasks[id] = nil
        stopFlushLoop(for: id)
        accumulators[id]?.reset()
        accumulators[id] = nil
        trainingTimings[id] = nil
        tabularAgents[id] = nil
        dqnAlgorithms[id] = nil
        sacAlgorithms[id] = nil
        renderSnapshots[id] = nil
        updateTrainingState(for: id) { $0.reset() }
        await reloadEnv(id: id)
    }

    func activeTrainingElapsed(for id: String) -> TimeInterval {
        trainingTimings[id]?.activeElapsed(now: .now) ?? 0
    }

    @MainActor
    func runTraining(
        for id: String,
        config: TrainingConfig,
        accumulator: TrainingAccumulator,
        isResuming: Bool = false
    ) async {
        guard env(for: id) != nil else {
            updateTrainingState(for: id) {
                $0.status = .failed("Environment not loaded")
            }
            return
        }

        defer {
            flushAccumulator(for: id)
            stopFlushLoop(for: id)
        }

        let totalTimesteps = config.totalTimesteps
        let renderEnabled = config.renderDuringTraining
        let renderFPS = config.renderFPS

        do {
            switch config.algorithm {
            case .qLearning, .sarsa:
                try await runTabularTraining(
                    id: id,
                    config: config,
                    totalTimesteps: totalTimesteps,
                    renderEnabled: renderEnabled,
                    renderFPS: renderFPS,
                    accumulator: accumulator
                )
            case .dqn:
                try await runDQNTraining(
                    id: id,
                    config: config,
                    totalTimesteps: totalTimesteps,
                    renderEnabled: renderEnabled,
                    renderFPS: renderFPS,
                    isResuming: isResuming,
                    accumulator: accumulator
                )
            case .sac:
                try await runSACTraining(
                    id: id,
                    config: config,
                    totalTimesteps: totalTimesteps,
                    renderEnabled: renderEnabled,
                    renderFPS: renderFPS,
                    isResuming: isResuming,
                    accumulator: accumulator
                )
            }
        } catch {
            updateTrainingState(for: id) {
                $0.status = .failed(error.localizedDescription)
            }
            return
        }

        if trainingState(for: id).status == .training {
            updateTrainingState(for: id) { $0.status = .completed }
        }
    }

    func runTabularTraining(
        id: String,
        config: TrainingConfig,
        totalTimesteps: Int,
        renderEnabled: Bool,
        renderFPS: Int,
        accumulator: TrainingAccumulator
    ) async throws {
        guard let env = env(for: id) else {
            throw TrainError.environmentNotLoaded
        }

        let agent: TabularAgent
        if let existing = tabularAgents[id] {
            agent = existing
        } else {
            let tabularConfig = TabularConfig(
                learningRate: config.tabular.learningRate,
                gamma: config.tabular.gamma,
                epsilon: config.tabular.epsilon,
                epsilonDecay: config.tabular.epsilonDecay,
                minEpsilon: config.tabular.minEpsilon
            )
            let updateRule: TabularAgent.UpdateRule =
                config.algorithm == .sarsa ? .sarsa : .qLearning
            let info = TabularAgent.stateSpaceInfo(from: env.observationSpace)
            agent = TabularAgent(
                updateRule: updateRule,
                config: tabularConfig,
                numStates: info.numStates,
                numActions: (env.actionSpace as! Discrete).n,
                seed: config.seedValue,
                stateStrides: info.strides
            )
            tabularAgents[id] = agent
        }
        agent.setEnv(env)

        let callbacks = makeCallbacks(
            for: id,
            accumulator: accumulator,
            renderEnabled: renderEnabled,
            renderFPS: renderFPS,
            onFlush: { [weak self] in self?.flushAccumulator(for: id) }
        )

        try await agent.learn(
            totalTimesteps: totalTimesteps,
            callbacks: callbacks,
            resetProgress: false
        )

        if let finalEnv = agent.takeEnv() {
            envStates[id] = .loaded(finalEnv)
        }
    }

    func runDQNTraining(
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

        let dqn = try dqnAlgorithm(for: id, env: env, config: config)

        if !isResuming {
            updateTrainingState(for: id) { s in
                s.currentTimestep = 0
                s.explorationRate = config.dqn.explorationInitialEps
            }
            trainingTimings[id] = TrainingTiming(startedAt: .now)
        }

        let callbacks = makeCallbacks(
            for: id,
            accumulator: accumulator,
            renderEnabled: renderEnabled,
            renderFPS: renderFPS,
            onFlush: { [weak self] in self?.flushAccumulator(for: id) }
        )

        try await dqn.learn(
            totalTimesteps: totalTimesteps,
            callbacks: callbacks,
            resetProgress: !isResuming
        )

        if let finalEnv = dqn.takeEnv() {
            envStates[id] = .loaded(finalEnv)
        }
    }

    func dqnAlgorithm(for id: String, env: any Env, config: TrainingConfig)
        throws -> DQN
    {
        let resetOptions = envResetOptions(for: id)
        let resetSeed = envResetSeed(for: id)
        let configuredEnv = ConfiguredEnv(
            base: env,
            resetSeed: resetSeed,
            resetOptions: resetOptions
        )

        if let existing = dqnAlgorithms[id] {
            existing.setEnv(configuredEnv)
            return existing
        }

        guard let actionSpace = configuredEnv.actionSpace as? Discrete else {
            throw TrainError.invalidConfiguration(
                "DQN requires a discrete action space"
            )
        }

        let trainFrequency = TrainFrequency(
            frequency: max(1, config.dqn.trainFrequency),
            unit: trainFrequencyUnit(from: config.dqn.trainFrequencyUnit)
        )
        let gradientSteps = gradientSteps(
            mode: config.dqn.gradientStepsMode,
            count: config.dqn.gradientSteps
        )
        let maxGradNorm =
            config.dqn.maxGradNorm > 0 ? config.dqn.maxGradNorm : nil

        let dqnConfig = DQNConfig(
            bufferSize: config.dqn.bufferSize,
            learningStarts: config.dqn.learningStarts,
            batchSize: config.dqn.batchSize,
            tau: config.dqn.tau,
            gamma: config.dqn.gamma,
            trainFrequency: trainFrequency,
            gradientSteps: gradientSteps,
            targetUpdateInterval: config.dqn.targetUpdateInterval,
            explorationFraction: config.dqn.explorationFraction,
            explorationInitialEps: config.dqn.explorationInitialEps,
            explorationFinalEps: config.dqn.explorationFinalEps,
            maxGradNorm: maxGradNorm,
            optimizeMemoryUsage: config.dqn.optimizeMemoryUsage,
            handleTimeoutTermination: config.dqn.handleTimeoutTermination
        )

        let policyConfig = DQNPolicyConfig(
            netArch: config.dqn.netArch,
            featuresExtractor: .auto,
            activation: activationConfig(from: config.dqn.activation),
            normalizeImages: config.dqn.normalizeImages
        )

        let optimizerConfig = DQNOptimizerConfig(
            optimizer: .adam(
                beta1: config.dqn.optimizerBeta1,
                beta2: config.dqn.optimizerBeta2,
                eps: config.dqn.optimizerEps
            )
        )

        let learningRate = learningRateSchedule(
            schedule: config.dqn.learningRateSchedule,
            initial: Double(config.dqn.learningRate),
            final: Double(config.dqn.learningRateFinal),
            decayRate: Double(config.dqn.learningRateDecayRate),
            minValue: Double(config.dqn.learningRateMinValue),
            milestones: parseMilestones(config.dqn.learningRateMilestones),
            gamma: Double(config.dqn.learningRateGamma),
            warmupEnabled: config.dqn.warmupEnabled,
            warmupFraction: config.dqn.warmupFraction,
            warmupInitial: Double(config.dqn.warmupInitialValue)
        )

        let dqn = DQN(
            observationSpace: configuredEnv.observationSpace,
            actionSpace: actionSpace,
            learningRate: learningRate,
            policyConfig: policyConfig,
            config: dqnConfig,
            optimizerConfig: optimizerConfig,
            seed: config.seedValue
        )
        dqn.setEnv(configuredEnv)

        dqnAlgorithms[id] = dqn
        return dqn
    }

    func runSACTraining(
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

        let sac = sacAlgorithm(for: id, env: env, config: config)

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
            onFlush: { [weak self] in self?.flushAccumulator(for: id) }
        )

        try await sac.learn(
            totalTimesteps: totalTimesteps,
            callbacks: callbacks,
            resetProgress: !isResuming
        )

        if let finalEnv = sac.takeEnv() {
            envStates[id] = .loaded(finalEnv)
        }
    }

    func sacAlgorithm(for id: String, env: any Env, config: TrainingConfig)
        -> SAC
    {
        let resetOptions = envResetOptions(for: id)
        let resetSeed = envResetSeed(for: id)
        let configuredEnv = ConfiguredEnv(
            base: env,
            resetSeed: resetSeed,
            resetOptions: resetOptions
        )

        if let existing = sacAlgorithms[id] {
            existing.setEnv(configuredEnv)
            return existing
        }

        let trainFrequency = TrainFrequency(
            frequency: max(1, config.sac.trainFrequency),
            unit: trainFrequencyUnit(from: config.sac.trainFrequencyUnit)
        )
        let gradientSteps = gradientSteps(
            mode: config.sac.gradientStepsMode,
            count: config.sac.gradientSteps
        )

        let offPolicyConfig = OffPolicyConfig(
            bufferSize: config.sac.bufferSize,
            learningStarts: config.sac.learningStarts,
            batchSize: config.sac.batchSize,
            tau: config.sac.tau,
            gamma: config.sac.gamma,
            trainFrequency: trainFrequency,
            gradientSteps: gradientSteps,
            targetUpdateInterval: config.sac.targetUpdateInterval,
            optimizeMemoryUsage: config.sac.optimizeMemoryUsage,
            handleTimeoutTermination: config.sac.handleTimeoutTermination,
            useSDEAtWarmup: config.sac.useSDEAtWarmup,
            sdeSampleFreq: config.sac.sdeSampleFreq,
            sdeSupported: true
        )

        let netArch: NetArch =
            config.sac.useSeparateNetworks
            ? .separate(
                actor: config.sac.netArch,
                critic: config.sac.criticNetArch
            )
            : .shared(config.sac.netArch)

        let actorFeaturesExtractor: FeaturesExtractorConfig = .auto
        let criticFeaturesExtractor: FeaturesExtractorConfig? =
            config.sac.shareFeaturesExtractor ? nil : .auto
        let actorActivation = activationConfig(from: config.sac.activation)
        let criticActivation = activationConfig(
            from: config.sac.shareFeaturesExtractor
                ? config.sac.activation : config.sac.criticActivation
        )
        let criticNormalizeImages =
            config.sac.shareFeaturesExtractor
            ? config.sac.normalizeImages
            : config.sac.criticNormalizeImages
        let criticNetArch =
            config.sac.useSeparateNetworks ? config.sac.criticNetArch : nil

        let networksConfig = SACNetworksConfig(
            actor: SACActorConfig(
                netArch: netArch,
                featuresExtractor: actorFeaturesExtractor,
                activation: actorActivation,
                useSDE: config.sac.useSDE,
                logStdInit: config.sac.logStdInit,
                fullStd: config.sac.fullStd,
                clipMean: config.sac.clipMean,
                normalizeImages: config.sac.normalizeImages
            ),
            critic: SACCriticConfig(
                netArch: criticNetArch,
                nCritics: config.sac.nCritics,
                shareFeaturesExtractor: config.sac.shareFeaturesExtractor,
                featuresExtractor: criticFeaturesExtractor,
                normalizeImages: criticNormalizeImages,
                activation: criticActivation
            )
        )

        let entCoef: EntropyCoef =
            config.sac.autoEntropyTuning
            ? .auto(init: config.sac.autoEntropyInit)
            : .fixed(config.sac.fixedEntCoef)
        let targetEntropy =
            config.sac.useTargetEntropy ? config.sac.targetEntropy : nil
        let entropyOptimizer: OptimizerConfig? =
            config.sac.autoEntropyTuning
            ? .adam(
                beta1: config.sac.optimizerEntropyBeta1,
                beta2: config.sac.optimizerEntropyBeta2,
                eps: config.sac.optimizerEntropyEps
            )
            : nil
        let optimizerConfig = SACOptimizerConfig(
            actor: .adam(
                beta1: config.sac.optimizerActorBeta1,
                beta2: config.sac.optimizerActorBeta2,
                eps: config.sac.optimizerActorEps
            ),
            critic: .adam(
                beta1: config.sac.optimizerCriticBeta1,
                beta2: config.sac.optimizerCriticBeta2,
                eps: config.sac.optimizerCriticEps
            ),
            entropy: entropyOptimizer
        )

        let learningRate = learningRateSchedule(
            schedule: config.sac.learningRateSchedule,
            initial: Double(config.sac.learningRate),
            final: Double(config.sac.learningRateFinal),
            decayRate: Double(config.sac.learningRateDecayRate),
            minValue: Double(config.sac.learningRateMinValue),
            milestones: parseMilestones(config.sac.learningRateMilestones),
            gamma: Double(config.sac.learningRateGamma),
            warmupEnabled: config.sac.warmupEnabled,
            warmupFraction: config.sac.warmupFraction,
            warmupInitial: Double(config.sac.warmupInitialValue)
        )

        let sac = SAC(
            observationSpace: configuredEnv.observationSpace,
            actionSpace: configuredEnv.actionSpace,
            learningRate: learningRate,
            networksConfig: networksConfig,
            config: offPolicyConfig,
            optimizerConfig: optimizerConfig,
            entCoef: entCoef,
            targetEntropy: targetEntropy,
            seed: config.seedValue
        )
        sac.setEnv(configuredEnv)

        sacAlgorithms[id] = sac
        return sac
    }

    private func trainFrequencyUnit(from raw: String) -> TrainFrequencyUnit {
        switch raw.lowercased() {
        case "episode":
            return .episode
        default:
            return .step
        }
    }

    private func gradientSteps(mode: String, count: Int) -> GradientSteps {
        if count < 0 {
            return .asCollectedSteps
        }
        if mode.lowercased() == "ascollectedsteps" {
            return .asCollectedSteps
        }
        return .fixed(max(1, count))
    }

    private func activationConfig(from raw: String) -> ActivationConfig {
        switch raw.lowercased() {
        case "relu":
            return .relu
        default:
            return .relu
        }
    }

    private func learningRateSchedule(
        schedule: String,
        initial: Double,
        final: Double,
        decayRate: Double,
        minValue: Double,
        milestones: [Double],
        gamma: Double,
        warmupEnabled: Bool,
        warmupFraction: Double,
        warmupInitial: Double
    ) -> any LearningRateSchedule {
        let base: any LearningRateSchedule
        switch schedule.lowercased() {
        case "linear":
            base = LinearSchedule(initialValue: initial, finalValue: final)
        case "exponential":
            base = ExponentialSchedule(
                initialValue: initial,
                decayRate: decayRate
            )
        case "step":
            base = StepSchedule(
                initialValue: initial,
                milestones: milestones,
                gamma: gamma
            )
        case "cosine":
            base = CosineAnnealingSchedule(
                initialValue: initial,
                minValue: minValue
            )
        default:
            base = ConstantLearningRate(initial)
        }

        if warmupEnabled, warmupFraction > 0 {
            return WarmupSchedule(
                baseSchedule: base,
                warmupFraction: warmupFraction,
                warmupInitialValue: warmupInitial
            )
        }
        return base
    }

    private func parseMilestones(_ raw: String) -> [Double] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [0.5, 0.75] }
        let parts = trimmed.split { char in
            char == "," || char == " " || char == "\n" || char == "\t"
                || char == ";"
        }
        let values = parts.compactMap { Double($0) }.filter { $0 > 0 && $0 < 1 }
        return values.isEmpty ? [0.5, 0.75] : values
    }
}

private func makeCallbacks(
    for id: String,
    accumulator: TrainingAccumulator,
    renderEnabled: Bool,
    renderFPS: Int,
    onFlush: @Sendable @MainActor @escaping () -> Void
) -> LearnCallbacks {
    let snapshotHandler: LearnCallbacks.OnSnapshotCallback? =
        renderEnabled
        ? { @Sendable (snapshot: any Sendable) in
            accumulator.recordSnapshot(snapshot)
            Task { @MainActor in onFlush() }
            if renderFPS > 0 {
                try? await Task.sleep(
                    for: .seconds(1.0 / Double(renderFPS))
                )
            }
        } : nil

    return LearnCallbacks(
        onStep: { @Sendable currentStep, _, explorationRate in
            accumulator.recordStep(
                timestep: currentStep,
                explorationRate: explorationRate
            )
            return !Task.isCancelled
        },
        onEpisodeEnd: { @Sendable reward, length in
            accumulator.recordEpisode(reward: reward, length: length)
        },
        onSnapshot: snapshotHandler,
        onTrain: { @Sendable metrics in
            accumulator.recordMetrics(metrics)
        }
    )
}

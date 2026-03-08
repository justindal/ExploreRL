//
//  TrainViewModel+Training.swift
//  ExploreRL
//

import Foundation
import Gymnazo

extension TrainViewModel {

    func startTraining(for id: String) {
        guard trainingPolicy(for: id).isAllowed else { return }
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
        Task { await ppoAlgorithms[id]?.stop() }
        Task { await sacAlgorithms[id]?.stop() }
        Task { await td3Algorithms[id]?.stop() }
        trainingTimings[id]?.pause(at: .now)
        flushAccumulator(for: id)
        stopFlushLoop(for: id)
        updateTrainingState(for: id) { $0.status = .paused }
    }

    func resumeTraining(for id: String) {
        guard trainingState(for: id).status == .paused else { return }
        guard trainingPolicy(for: id).isAllowed else { return }
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
        guard !resettingEnvs.contains(id) else { return }
        resettingEnvs.insert(id)
        defer { resettingEnvs.remove(id) }

        let trainingTask = trainingTasks[id]
        let tabularAgent = tabularAgents[id]
        let dqn = dqnAlgorithms[id]
        let ppo = ppoAlgorithms[id]
        let sac = sacAlgorithms[id]
        let td3 = td3Algorithms[id]

        trainingTask?.cancel()
        await tabularAgent?.stop()
        await dqn?.stop()
        await ppo?.stop()
        await sac?.stop()
        await td3?.stop()
        if let trainingTask {
            await trainingTask.value
        }

        trainingTasks[id] = nil
        stopFlushLoop(for: id)
        accumulators[id]?.reset()
        accumulators[id] = nil
        trainingTimings[id] = nil
        tabularAgents[id] = nil
        dqnAlgorithms[id] = nil
        ppoAlgorithms[id] = nil
        sacAlgorithms[id] = nil
        td3Algorithms[id] = nil
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
            case .ppo:
                try await runPPOTraining(
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
            case .td3:
                try await runTD3Training(
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
            trackExplorationRate: true,
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
            let dqnSettings = sanitizedDQNHyperparameters(config.dqn)
            updateTrainingState(for: id) { s in
                s.currentTimestep = 0
                s.explorationRate = dqnSettings.explorationInitialEps
            }
            trainingTimings[id] = TrainingTiming(startedAt: .now)
        }

        let callbacks = makeCallbacks(
            for: id,
            accumulator: accumulator,
            renderEnabled: renderEnabled,
            renderFPS: renderFPS,
            trackExplorationRate: true,
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
        let dqnSettings = sanitizedDQNHyperparameters(config.dqn)

        let trainFrequency = TrainFrequency(
            frequency: max(1, dqnSettings.trainFrequency),
            unit: trainFrequencyUnit(from: dqnSettings.trainFrequencyUnit)
        )
        let gradientSteps = gradientSteps(
            mode: dqnSettings.gradientStepsMode,
            count: dqnSettings.gradientSteps
        )
        let maxGradNorm =
            dqnSettings.maxGradNorm > 0 ? dqnSettings.maxGradNorm : nil

        let dqnConfig = DQNConfig(
            bufferSize: dqnSettings.bufferSize,
            learningStarts: dqnSettings.learningStarts,
            batchSize: dqnSettings.batchSize,
            tau: dqnSettings.tau,
            gamma: dqnSettings.gamma,
            trainFrequency: trainFrequency,
            gradientSteps: gradientSteps,
            targetUpdateInterval: dqnSettings.targetUpdateInterval,
            explorationFraction: dqnSettings.explorationFraction,
            explorationInitialEps: dqnSettings.explorationInitialEps,
            explorationFinalEps: dqnSettings.explorationFinalEps,
            maxGradNorm: maxGradNorm,
            optimizeMemoryUsage: dqnSettings.optimizeMemoryUsage,
            handleTimeoutTermination: dqnSettings.handleTimeoutTermination
        )

        let policyConfig = DQNPolicyConfig(
            netArch: dqnSettings.netArch,
            featuresExtractor: .auto,
            activation: activationConfig(from: dqnSettings.activation),
            normalizeImages: dqnSettings.normalizeImages
        )

        let optimizerConfig = DQNOptimizerConfig(
            optimizer: .adam(
                beta1: dqnSettings.optimizerBeta1,
                beta2: dqnSettings.optimizerBeta2,
                eps: dqnSettings.optimizerEps
            )
        )

        let learningRate = learningRateSchedule(
            schedule: dqnSettings.learningRateSchedule,
            initial: Double(dqnSettings.learningRate),
            final: Double(dqnSettings.learningRateFinal),
            decayRate: Double(dqnSettings.learningRateDecayRate),
            minValue: Double(dqnSettings.learningRateMinValue),
            milestones: parseMilestones(dqnSettings.learningRateMilestones),
            gamma: Double(dqnSettings.learningRateGamma),
            warmupEnabled: dqnSettings.warmupEnabled,
            warmupFraction: dqnSettings.warmupFraction,
            warmupInitial: Double(dqnSettings.warmupInitialValue)
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
            trackExplorationRate: false,
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
        let sacSettings = sanitizedSACHyperparameters(config.sac)

        let trainFrequency = TrainFrequency(
            frequency: max(1, sacSettings.trainFrequency),
            unit: trainFrequencyUnit(from: sacSettings.trainFrequencyUnit)
        )
        let gradientSteps = gradientSteps(
            mode: sacSettings.gradientStepsMode,
            count: sacSettings.gradientSteps
        )

        let offPolicyConfig = OffPolicyConfig(
            bufferSize: sacSettings.bufferSize,
            learningStarts: sacSettings.learningStarts,
            batchSize: sacSettings.batchSize,
            tau: sacSettings.tau,
            gamma: sacSettings.gamma,
            trainFrequency: trainFrequency,
            gradientSteps: gradientSteps,
            targetUpdateInterval: sacSettings.targetUpdateInterval,
            optimizeMemoryUsage: sacSettings.optimizeMemoryUsage,
            handleTimeoutTermination: sacSettings.handleTimeoutTermination,
            useSDEAtWarmup: sacSettings.useSDEAtWarmup,
            sdeSampleFreq: sacSettings.sdeSampleFreq,
            sdeSupported: true
        )

        let netArch: NetArch =
            sacSettings.useSeparateNetworks
            ? .separate(
                actor: sacSettings.netArch,
                critic: sacSettings.criticNetArch
            )
            : .shared(sacSettings.netArch)

        let actorFeaturesExtractor: FeaturesExtractorConfig = .auto
        let criticFeaturesExtractor: FeaturesExtractorConfig? =
            sacSettings.shareFeaturesExtractor ? nil : .auto
        let actorActivation = activationConfig(from: sacSettings.activation)
        let criticActivation = activationConfig(
            from: sacSettings.shareFeaturesExtractor
                ? sacSettings.activation : sacSettings.criticActivation
        )
        let criticNormalizeImages =
            sacSettings.shareFeaturesExtractor
            ? sacSettings.normalizeImages
            : sacSettings.criticNormalizeImages
        let criticNetArch =
            sacSettings.useSeparateNetworks ? sacSettings.criticNetArch : nil

        let networksConfig = SACNetworksConfig(
            actor: SACActorConfig(
                netArch: netArch,
                featuresExtractor: actorFeaturesExtractor,
                activation: actorActivation,
                useSDE: sacSettings.useSDE,
                logStdInit: sacSettings.logStdInit,
                fullStd: sacSettings.fullStd,
                clipMean: sacSettings.clipMean,
                normalizeImages: sacSettings.normalizeImages
            ),
            critic: SACCriticConfig(
                netArch: criticNetArch,
                nCritics: sacSettings.nCritics,
                shareFeaturesExtractor: sacSettings.shareFeaturesExtractor,
                featuresExtractor: criticFeaturesExtractor,
                normalizeImages: criticNormalizeImages,
                activation: criticActivation
            )
        )

        let entCoef: EntropyCoef =
            sacSettings.autoEntropyTuning
            ? .auto(init: sacSettings.autoEntropyInit)
            : .fixed(sacSettings.fixedEntCoef)
        let targetEntropy =
            sacSettings.useTargetEntropy ? sacSettings.targetEntropy : nil
        let entropyOptimizer: OptimizerConfig? =
            sacSettings.autoEntropyTuning
            ? .adam(
                beta1: sacSettings.optimizerEntropyBeta1,
                beta2: sacSettings.optimizerEntropyBeta2,
                eps: sacSettings.optimizerEntropyEps
            )
            : nil
        let optimizerConfig = SACOptimizerConfig(
            actor: .adam(
                beta1: sacSettings.optimizerActorBeta1,
                beta2: sacSettings.optimizerActorBeta2,
                eps: sacSettings.optimizerActorEps
            ),
            critic: .adam(
                beta1: sacSettings.optimizerCriticBeta1,
                beta2: sacSettings.optimizerCriticBeta2,
                eps: sacSettings.optimizerCriticEps
            ),
            entropy: entropyOptimizer
        )

        let learningRate = learningRateSchedule(
            schedule: sacSettings.learningRateSchedule,
            initial: Double(sacSettings.learningRate),
            final: Double(sacSettings.learningRateFinal),
            decayRate: Double(sacSettings.learningRateDecayRate),
            minValue: Double(sacSettings.learningRateMinValue),
            milestones: parseMilestones(sacSettings.learningRateMilestones),
            gamma: Double(sacSettings.learningRateGamma),
            warmupEnabled: sacSettings.warmupEnabled,
            warmupFraction: sacSettings.warmupFraction,
            warmupInitial: Double(sacSettings.warmupInitialValue)
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

    private func sanitizedDQNHyperparameters(_ values: DQNHyperparameters) -> DQNHyperparameters {
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
        output.explorationFraction = clamp(output.explorationFraction, min: 1e-9, max: 1.0)
        output.explorationInitialEps = clamp(output.explorationInitialEps, min: 0.0, max: 1.0)
        output.explorationFinalEps = clamp(
            output.explorationFinalEps,
            min: 0.0,
            max: output.explorationInitialEps
        )
        output.targetUpdateInterval = max(1, output.targetUpdateInterval)
        output.trainFrequency = max(1, output.trainFrequency)
        output.gradientSteps = output.gradientSteps == -1 ? -1 : max(1, output.gradientSteps)
        output.maxGradNorm = max(0.0, output.maxGradNorm)
        output.netArch = output.netArch.filter { $0 > 0 }
        if output.netArch.isEmpty {
            output.netArch = [64, 64]
        }
        output.optimizerBeta1 = clamp(output.optimizerBeta1, min: 0.0, max: 0.999_999)
        output.optimizerBeta2 = clamp(output.optimizerBeta2, min: 0.0, max: 0.999_999)
        output.optimizerEps = max(output.optimizerEps, 1e-12)
        if output.optimizeMemoryUsage && output.handleTimeoutTermination {
            output.optimizeMemoryUsage = false
        }
        return output
    }

    private func sanitizedSACHyperparameters(_ values: SACHyperparameters) -> SACHyperparameters {
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
        output.targetUpdateInterval = max(1, output.targetUpdateInterval)
        output.trainFrequency = max(1, output.trainFrequency)
        output.gradientSteps = output.gradientSteps == -1 ? -1 : max(1, output.gradientSteps)
        output.autoEntropyInit = max(output.autoEntropyInit, 1e-6)
        output.fixedEntCoef = max(output.fixedEntCoef, 0.0)
        output.netArch = output.netArch.filter { $0 > 0 }
        if output.netArch.isEmpty {
            output.netArch = [256, 256]
        }
        output.criticNetArch = output.criticNetArch.filter { $0 > 0 }
        if output.criticNetArch.isEmpty {
            output.criticNetArch = output.netArch
        }
        output.sdeSampleFreq = output.sdeSampleFreq < 0 ? -1 : output.sdeSampleFreq
        output.clipMean = max(output.clipMean, 0.0)
        output.nCritics = max(1, output.nCritics)
        output.optimizerActorBeta1 = clamp(output.optimizerActorBeta1, min: 0.0, max: 0.999_999)
        output.optimizerActorBeta2 = clamp(output.optimizerActorBeta2, min: 0.0, max: 0.999_999)
        output.optimizerActorEps = max(output.optimizerActorEps, 1e-12)
        output.optimizerCriticBeta1 = clamp(output.optimizerCriticBeta1, min: 0.0, max: 0.999_999)
        output.optimizerCriticBeta2 = clamp(output.optimizerCriticBeta2, min: 0.0, max: 0.999_999)
        output.optimizerCriticEps = max(output.optimizerCriticEps, 1e-12)
        output.optimizerEntropyBeta1 = clamp(output.optimizerEntropyBeta1, min: 0.0, max: 0.999_999)
        output.optimizerEntropyBeta2 = clamp(output.optimizerEntropyBeta2, min: 0.0, max: 0.999_999)
        output.optimizerEntropyEps = max(output.optimizerEntropyEps, 1e-12)
        if output.optimizeMemoryUsage && output.handleTimeoutTermination {
            output.optimizeMemoryUsage = false
        }
        return output
    }

    func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
        min(max(value, minValue), maxValue)
    }

    func trainFrequencyUnit(from raw: String) -> TrainFrequencyUnit {
        switch raw.lowercased() {
        case "episode":
            return .episode
        default:
            return .step
        }
    }

    func gradientSteps(mode: GradientStepsMode, count: Int) -> GradientSteps {
        if count < 0 {
            return .asCollectedSteps
        }
        if mode == .asCollectedSteps {
            return .asCollectedSteps
        }
        return .fixed(max(1, count))
    }

    func activationConfig(from raw: String) -> ActivationConfig {
        switch raw.lowercased() {
        case "relu":
            return .relu
        case "tanh":
            return .tanh
        default:
            return .relu
        }
    }

    func learningRateSchedule(
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

    func parseMilestones(_ raw: String) -> [Double] {
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

func makeCallbacks(
    for id: String,
    accumulator: TrainingAccumulator,
    renderEnabled: Bool,
    renderFPS: Int,
    trackExplorationRate: Bool = true,
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
            let rateToRecord: Double? = trackExplorationRate ? explorationRate : nil
            accumulator.recordStep(
                timestep: currentStep,
                explorationRate: rateToRecord
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

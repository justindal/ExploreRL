import Foundation
import Gymnazo

extension TrainViewModel {
    func runPPOTraining(
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

        let ppo = try ppoAlgorithm(for: id, env: env, config: config)

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

        try await ppo.learn(
            totalTimesteps: totalTimesteps,
            callbacks: callbacks,
            resetProgress: !isResuming
        )

        if let finalEnv = ppo.takeEnv() {
            envStates[id] = .loaded(finalEnv)
        }
    }

    func ppoAlgorithm(for id: String, env: any Env, config: TrainingConfig) throws -> PPO {
        let resetOptions = envResetOptions(for: id)
        let resetSeed = envResetSeed(for: id)
        let configuredEnv = ConfiguredEnv(
            base: env,
            resetSeed: resetSeed,
            resetOptions: resetOptions
        )

        if let existing = ppoAlgorithms[id] {
            existing.setEnv(configuredEnv)
            return existing
        }

        var ppoSettings = sanitizedPPOHyperparameters(config.ppo)
        if !(configuredEnv.actionSpace is Box) {
            ppoSettings.useSDE = false
            ppoSettings.sdeSampleFreq = -1
        }

        let ppoConfig = PPOConfig(
            nSteps: ppoSettings.nSteps,
            batchSize: ppoSettings.batchSize,
            nEpochs: ppoSettings.nEpochs,
            gamma: ppoSettings.gamma,
            gaeLambda: ppoSettings.gaeLambda,
            clipRange: ppoSettings.clipRange,
            clipRangeVf: ppoSettings.clipRangeVfEnabled ? ppoSettings.clipRangeVf : nil,
            normalizeAdvantage: ppoSettings.normalizeAdvantage,
            entCoef: ppoSettings.entCoef,
            vfCoef: ppoSettings.vfCoef,
            maxGradNorm: ppoSettings.maxGradNorm,
            targetKL: ppoSettings.targetKLEnabled ? ppoSettings.targetKL : nil,
            useSDE: ppoSettings.useSDE,
            sdeSampleFreq: ppoSettings.sdeSampleFreq
        )

        let policyConfig = PPOPolicyConfig(
            netArch: .shared(ppoSettings.netArch),
            featuresExtractor: .auto,
            activation: activationConfig(from: ppoSettings.activation),
            normalizeImages: ppoSettings.normalizeImages,
            shareFeaturesExtractor: ppoSettings.shareFeaturesExtractor,
            orthoInit: ppoSettings.orthoInit,
            logStdInit: ppoSettings.logStdInit,
            fullStd: ppoSettings.fullStd
        )

        let learningRate = learningRateSchedule(
            schedule: ppoSettings.learningRateSchedule,
            initial: Double(ppoSettings.learningRate),
            final: Double(ppoSettings.learningRateFinal),
            decayRate: Double(ppoSettings.learningRateDecayRate),
            minValue: Double(ppoSettings.learningRateMinValue),
            milestones: parseMilestones(ppoSettings.learningRateMilestones),
            gamma: Double(ppoSettings.learningRateGamma),
            warmupEnabled: ppoSettings.warmupEnabled,
            warmupFraction: ppoSettings.warmupFraction,
            warmupInitial: Double(ppoSettings.warmupInitialValue)
        )

        let ppo = try PPO(
            observationSpace: configuredEnv.observationSpace,
            actionSpace: configuredEnv.actionSpace,
            learningRate: learningRate,
            policyConfig: policyConfig,
            config: ppoConfig,
            seed: config.seedValue
        )
        ppo.setEnv(configuredEnv)

        ppoAlgorithms[id] = ppo
        return ppo
    }

    private func sanitizedPPOHyperparameters(_ values: PPOHyperparameters) -> PPOHyperparameters {
        var output = values
        output.learningRate = max(output.learningRate, 1e-12)
        output.learningRateFinal = max(output.learningRateFinal, 0.0)
        output.learningRateDecayRate = max(output.learningRateDecayRate, 1e-6)
        output.learningRateMinValue = max(output.learningRateMinValue, 0.0)
        output.learningRateGamma = max(output.learningRateGamma, 1e-6)
        output.warmupFraction = clamp(output.warmupFraction, min: 0.0, max: 1.0)
        output.warmupInitialValue = max(output.warmupInitialValue, 0.0)
        output.nSteps = max(1, output.nSteps)
        output.batchSize = max(1, output.batchSize)
        output.nEpochs = max(1, output.nEpochs)
        output.gamma = clamp(output.gamma, min: 0.0, max: 1.0)
        output.gaeLambda = clamp(output.gaeLambda, min: 0.0, max: 1.0)
        output.clipRange = max(0.0, output.clipRange)
        output.clipRangeVf = max(0.0, output.clipRangeVf)
        output.entCoef = max(0.0, output.entCoef)
        output.vfCoef = max(0.0, output.vfCoef)
        output.maxGradNorm = max(0.0, output.maxGradNorm)
        output.targetKL = max(0.0, output.targetKL)
        output.sdeSampleFreq = output.sdeSampleFreq < 0 ? -1 : output.sdeSampleFreq
        output.netArch = output.netArch.filter { $0 > 0 }
        if output.netArch.isEmpty {
            output.netArch = [64, 64]
        }
        if !output.useSDE {
            output.sdeSampleFreq = -1
        }
        return output
    }
}

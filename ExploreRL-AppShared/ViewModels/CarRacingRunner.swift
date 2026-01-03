import SwiftUI
import Gymnazo
import MLX
import MLXNN

@MainActor
@Observable class CarRacingRunner: SavableEnvironmentRunner {
    var snapshot: CarRacingSnapshot?
    var episodeCount = 1
    var currentStep = 0
    var episodeReward: Double = 0.0
    var isTraining = false
    var renderEnabled: Bool = TrainingDefaults.renderEnabled
    var episodeMetrics: [EpisodeMetrics] = []
    var episodesPerRun: Int = TrainingDefaults.episodesPerRun
    var targetFPS: Double = TrainingDefaults.targetFPS
    
    var loadedAgentId: UUID?
    var loadedAgentName: String?
    var hasTrainedSinceLoad = false
    
    private var loadedEpisodeCount: Int = 0
    private var loadedBestReward: Double = -100
    private var trainingCompletedNormally = false
    private var committedEpisodeMetricsCount: Int = 0
    
    private(set) var accumulatedTrainingTimeSeconds: TimeInterval = 0
    private(set) var trainingSessionStartDate: Date? = nil
    
    var totalTrainingTimeSeconds: TimeInterval {
        accumulatedTrainingTimeSeconds + (trainingSessionStartDate.map { Date().timeIntervalSince($0) } ?? 0)
    }
    
    var canResume: Bool {
        return agent != nil && episodeCount > 1 && !trainingCompletedNormally
    }
    
    private var uncommittedEpisodeCount: Int {
        return max(0, episodeMetrics.count - committedEpisodeMetricsCount)
    }
    
    var totalEpisodesTrained: Int {
        return loadedEpisodeCount + uncommittedEpisodeCount
    }
    
    var averageReward: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recent = episodeMetrics.suffix(movingAverageWindow)
        return recent.map { $0.reward }.reduce(0, +) / Double(recent.count)
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -100
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .carRacing }
    static var displayName: String { "Car Racing" }
    static var algorithmName: String { "SAC" }
    static var icon: String { "flag.checkered" }
    static var accentColor: Color { .pink }
    static var category: EnvironmentCategory { .box2d }
    
    var isRunning = false
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    var movingAverageWindow = 100
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    
    var learningRate: Double = Double(CarRacingSAC.Defaults.learningRate)
    var gamma: Double = Double(CarRacingSAC.Defaults.gamma)
    var tau: Double = Double(CarRacingSAC.Defaults.tau)
    var alpha: Double = 1.0
    var batchSize: Int = CarRacingSAC.Defaults.batchSize
    var bufferSize: Int = CarRacingSAC.Defaults.bufferSize
    var warmupSteps: Int = 1000
    var maxStepsPerEpisode: Int = 1000
    
    var autoAlpha: Bool = true
    var initAlpha: Double = 1.0
    var alphaLr: Double = 0.0003
    var trainFreqSteps: Int = 8
    var gradientStepsPerTrain: Int = 10
    
    var lapCompletePercent: Double = 0.95
    var domainRandomize: Bool = false
    
    var useFrameStack: Bool = true
    var frameStackSize: Int = 4
    var frameSkip: Int = 2
    var useSDE: Bool = true
    
    var currentObservationSize: Int {
        useFrameStack ? 144 * frameStackSize : 144
    }
    
    private var episodesCompletedInRun: Int = 0
    private var env: (any Env<MLXArray, MLXArray>)?
    private var rngKey: MLXArray
    private var agent: CarRacingSAC?
    private var totalSteps: Int = 0
    
    var isWarmingUp: Bool = false
    var warmupProgress: Double {
        guard warmupSteps > 0 else { return 1.0 }
        return min(1.0, Double(totalSteps) / Double(warmupSteps))
    }
    
    init() {
        self.rngKey = MLX.key(0)
        setupEnvironment()
    }
    
    func setupEnvironment() {
        var kwargs: [String: Any] = [
            "lap_complete_percent": Float(lapCompletePercent),
            "domain_randomize": domainRandomize
        ]
        if renderEnabled {
            kwargs["render_mode"] = "human"
        }

        guard let baseEnv = Gymnazo.make(
            "CarRacing",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: kwargs
        ) as? TimeLimit<OrderEnforcing<PassiveEnvChecker<CarRacing>>> else {
            print("Failed to create CarRacing environment")
            return
        }

        let grayscaleEnv = GrayscaleObservation(env: baseEnv)
        let resizedEnv = ResizeObservation(env: grayscaleEnv, shape: (12, 12))
        let normalizedEnv = NormalizeObservation(env: resizedEnv)
        let frameSkippedEnv = FrameSkip(env: normalizedEnv, skip: frameSkip)

        if useFrameStack {
            var env = FrameStackObservation(env: frameSkippedEnv, stackSize: frameStackSize, paddingType: .reset)
            let _ = env.reset()
            self.snapshot = renderEnabled ? (env.render() as? CarRacingSnapshot) : nil
            self.env = env
        } else {
            var env = frameSkippedEnv
            let _ = env.reset()
            self.snapshot = renderEnabled ? (env.render() as? CarRacingSnapshot) : nil
            self.env = env
        }
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(0)
        }
        
        if agent == nil {
            let entCoefMode: EntropyCoefficientMode
            if autoAlpha {
                entCoefMode = .auto(initAlpha: Float(initAlpha), alphaLr: Float(alphaLr), targetEntropy: nil)
            } else {
                entCoefMode = .fixed(alpha: Float(alpha))
            }
            
            agent = CarRacingSAC(
                observationSize: currentObservationSize,
                learningRate: Float(learningRate),
                gamma: Float(gamma),
                tau: Float(tau),
                batchSize: batchSize,
                bufferSize: bufferSize,
                useSDE: useSDE,
                entCoefMode: entCoefMode
            )
        }
        
        episodeMetrics.removeAll()
        committedEpisodeMetricsCount = 0
        episodeCount = 1
        currentStep = 0
        totalReward = 0
        episodeReward = 0
        totalSteps = 0
        episodesCompletedInRun = 0
    }
    
    private func updateSnapshot() {
        if renderEnabled {
            self.snapshot = self.env?.render() as? CarRacingSnapshot
        }
    }
    
    func reset() {
        stopTraining()
        stopRunning()
        accumulatedTrainingTimeSeconds = 0
        trainingSessionStartDate = nil
        agent = nil
        alpha = 1.0
        autoAlpha = true
        initAlpha = 1.0
        alphaLr = 0.0003
        trainFreqSteps = 1
        gradientStepsPerTrain = 1
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = -100
        trainingCompletedNormally = false
        committedEpisodeMetricsCount = 0
        setupEnvironment()
    }
    
    func resetToDefaults() {
        learningRate = Double(CarRacingSAC.Defaults.learningRate)
        gamma = Double(CarRacingSAC.Defaults.gamma)
        tau = Double(CarRacingSAC.Defaults.tau)
        alpha = 1.0
        autoAlpha = true
        initAlpha = 1.0
        alphaLr = 0.0003
        trainFreqSteps = 8
        gradientStepsPerTrain = 10
        batchSize = CarRacingSAC.Defaults.batchSize
        bufferSize = CarRacingSAC.Defaults.bufferSize
        
        warmupSteps = 1000
        renderEnabled = TrainingDefaults.renderEnabled
        episodesPerRun = TrainingDefaults.episodesPerRun
        episodesCompletedInRun = 0
        useSeed = TrainingDefaults.useSeed
        seed = TrainingDefaults.seed
        maxStepsPerEpisode = 1000
        targetFPS = TrainingDefaults.targetFPS
        turboMode = TrainingDefaults.turboMode
        lapCompletePercent = 0.95
        domainRandomize = false
        useFrameStack = true
        frameStackSize = 4
        frameSkip = 2
        useSDE = true
    }

    func startTraining() {
        guard !isTraining else { return }
        guard !TrainingState.shared.isTraining else { return }
        
        isTraining = true
        if trainingSessionStartDate == nil {
            trainingSessionStartDate = Date()
        }
        hasTrainedSinceLoad = true
        trainingCompletedNormally = false
        episodesCompletedInRun = 0
        TrainingState.shared.startTraining(environment: Self.displayName)
        
        Task.detached { [weak self] in
            await self?.trainingLoop()
        }
    }
    
    func stopTraining() {
        if let start = trainingSessionStartDate {
            accumulatedTrainingTimeSeconds += Date().timeIntervalSince(start)
            trainingSessionStartDate = nil
        }
        isTraining = false
        TrainingState.shared.stopTraining()
    }
    
    func stopRunning() {
        isRunning = false
    }
    
    func saveAgent(name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        let saved = try AgentStorage.shared.saveCarRacingAgent(
            name: name,
            actor: agent.actor,
            qEnsemble: agent.qEnsemble,
            logAlphaValue: agent.logAlphaModule.value,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            alpha: alpha,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "learningRate": learningRate,
                "gamma": gamma,
                "tau": tau,
                "alpha": alpha,
                "autoAlpha": autoAlpha ? 1.0 : 0.0,
                "initAlpha": initAlpha,
                "alphaLr": alphaLr,
                "trainFreqSteps": Double(trainFreqSteps),
                "gradientStepsPerTrain": Double(gradientStepsPerTrain),
                "batchSize": Double(batchSize),
                "bufferSize": Double(bufferSize),
                "warmupSteps": Double(warmupSteps),
                "totalSteps": Double(totalSteps)
            ],
            environmentConfig: [
                "maxStepsPerEpisode": "\(maxStepsPerEpisode)",
                "lap_complete_percent": "\(lapCompletePercent)",
                "domain_randomize": domainRandomize ? "true" : "false",
                "useFrameStack": useFrameStack ? "true" : "false",
                "frameStackSize": "\(frameStackSize)"
            ],
            observationSize: currentObservationSize
        )
        
        loadedAgentId = saved.id
        loadedAgentName = saved.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = totalEpisodesTrained
        committedEpisodeMetricsCount = episodeMetrics.count
        loadedBestReward = combinedBestReward
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func updateAgent(id: UUID, name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        try AgentStorage.shared.updateCarRacingAgent(
            id: id,
            newName: name,
            actor: agent.actor,
            qEnsemble: agent.qEnsemble,
            logAlphaValue: agent.logAlphaModule.value,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            alpha: alpha,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "learningRate": learningRate,
                "gamma": gamma,
                "tau": tau,
                "alpha": alpha,
                "autoAlpha": autoAlpha ? 1.0 : 0.0,
                "initAlpha": initAlpha,
                "alphaLr": alphaLr,
                "trainFreqSteps": Double(trainFreqSteps),
                "gradientStepsPerTrain": Double(gradientStepsPerTrain),
                "batchSize": Double(batchSize),
                "bufferSize": Double(bufferSize),
                "warmupSteps": Double(warmupSteps),
                "totalSteps": Double(totalSteps)
            ]
        )
        
        loadedAgentName = name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = totalEpisodesTrained
        committedEpisodeMetricsCount = episodeMetrics.count
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .carRacing else {
            throw AgentStorageError.wrongEnvironmentType
        }
        
        stopTraining()
        accumulatedTrainingTimeSeconds = savedAgent.trainingTimeSeconds ?? 0
        trainingSessionStartDate = nil
        
        if let lr = savedAgent.hyperparameters["learningRate"] { learningRate = lr }
        if let g = savedAgent.hyperparameters["gamma"] { gamma = g }
        if let t = savedAgent.hyperparameters["tau"] { tau = t }
        if let a = savedAgent.hyperparameters["alpha"] { alpha = a }
        if let aa = savedAgent.hyperparameters["autoAlpha"] { autoAlpha = aa > 0.5 }
        if let ia = savedAgent.hyperparameters["initAlpha"] { initAlpha = ia }
        if let alr = savedAgent.hyperparameters["alphaLr"] { alphaLr = alr }
        if let tf = savedAgent.hyperparameters["trainFreqSteps"] { trainFreqSteps = max(1, Int(tf)) }
        if let gs = savedAgent.hyperparameters["gradientStepsPerTrain"] { gradientStepsPerTrain = max(1, Int(gs)) }
        if let bs = savedAgent.hyperparameters["batchSize"] { batchSize = Int(bs) }
        if let buf = savedAgent.hyperparameters["bufferSize"] { bufferSize = Int(buf) }
        if let wSteps = savedAgent.hyperparameters["warmupSteps"] { warmupSteps = Int(wSteps) }
        if let tSteps = savedAgent.hyperparameters["totalSteps"] { totalSteps = Int(tSteps) }
        
        if let maxSteps = savedAgent.environmentConfig["maxStepsPerEpisode"],
           let steps = Int(maxSteps) {
            maxStepsPerEpisode = steps
        }
        if let lcp = savedAgent.environmentConfig["lap_complete_percent"],
           let lcpVal = Double(lcp) {
            lapCompletePercent = lcpVal
        }
        if let dr = savedAgent.environmentConfig["domain_randomize"] {
            domainRandomize = dr == "true"
        }
        
        let savedUseFrameStack = savedAgent.environmentConfig["useFrameStack"] == "true"
        let savedFrameStackSize = Int(savedAgent.environmentConfig["frameStackSize"] ?? "4") ?? 4
        
        if savedUseFrameStack != useFrameStack || (savedUseFrameStack && savedFrameStackSize != frameStackSize) {
            let savedDesc = savedUseFrameStack ? "FrameStack(\(savedFrameStackSize))" : "No FrameStack"
            let currentDesc = useFrameStack ? "FrameStack(\(frameStackSize))" : "No FrameStack"
            throw AgentStorageError.frameStackMismatch(saved: savedDesc, current: currentDesc)
        }
        
        agent = nil
        setupEnvironment()
        
        let weightsDict = try AgentStorage.shared.loadCarRacingWeights(for: savedAgent)
        
        guard let agent = self.agent else {
            throw AgentStorageError.dataCorrupted
        }
        
        let excludedActorKeys = Set([
            "actionScale", "actionBias", "epsilon", "logPiConstant",
            "logStdMinArray", "logStdRangeHalf"
        ])
        
        if let actorWeights = weightsDict["actor"] {
            let filteredWeights = actorWeights.filter { !excludedActorKeys.contains($0.key) }
            let actorTuples = filteredWeights.map { ($0.key, $0.value) }
            let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
            agent.actor.update(parameters: actorParams)
        }
        
        if let qEnsembleWeights = weightsDict["qEnsemble"] {
            let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
            let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
            agent.qEnsemble.update(parameters: qParams)
            agent.qEnsembleTarget.update(parameters: qParams)
        }
        
        if let entCoefWeights = weightsDict["entCoef"], let logAlpha = entCoefWeights["logAlpha"] {
            agent.logAlphaModule.value = logAlpha
            _ = agent.syncAlpha()
            self.alpha = Double(agent.alpha)
        }
        
        eval(agent.actor, agent.qEnsemble, agent.qEnsembleTarget, agent.logAlphaModule)
        
        episodeMetrics = []
        committedEpisodeMetricsCount = 0
        episodeCount = savedAgent.episodesTrained + 1
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
    }
    
    private func preprocessObservation(_ obs: MLXArray) -> MLXArray {
        return obs.asType(.float32).reshaped([currentObservationSize])
    }
    
    private func trainingLoop() async {
        guard var env = self.env else { return }
        
        guard let _ = env.observation_space as? Box,
              let _ = env.action_space as? Box,
              let sacAgent = self.agent else {
            await MainActor.run { self.stopTraining() }
            return
        }
        
        if totalSteps < warmupSteps {
            await MainActor.run { self.isWarmingUp = true }
            
            var warmupEnv = env
            let warmupResult = warmupEnv.reset()
            var warmupState = preprocessObservation(warmupResult.obs)
            
            if useSDE {
                let (newKey, noiseKey) = MLX.split(key: rngKey)
                rngKey = newKey
                sacAgent.actor.resetNoise(key: noiseKey)
            }
            
            let samplesToCollect = warmupSteps - totalSteps
            
            for i in 0..<samplesToCollect {
                let (newKey, actionKey) = MLX.split(key: rngKey)
                rngKey = newKey

                let (steerKey, gasBrakeKey) = MLX.split(key: actionKey)
                let (gasKey, brakeKey) = MLX.split(key: gasBrakeKey)

                let steer = MLX.uniform((-1.0 as Float)..<(1.0 as Float), [1], key: steerKey)
                let gas = MLX.uniform((0.0 as Float)..<(1.0 as Float), [1], key: gasKey)
                let brake = MLX.uniform((0.0 as Float)..<(1.0 as Float), [1], key: brakeKey)
                let action = concatenated([steer, gas, brake], axis: 0)
                
                let stepResult = warmupEnv.step(action)
                let nextState = preprocessObservation(stepResult.obs)
                
                sacAgent.store(
                    state: warmupState,
                    action: action,
                    reward: Float(stepResult.reward),
                    nextState: nextState,
                    terminated: stepResult.terminated
                )
                
                warmupState = nextState
                totalSteps += 1
                
                if stepResult.terminated || stepResult.truncated {
                    let resetResult = warmupEnv.reset()
                    warmupState = preprocessObservation(resetResult.obs)
                    
                    if useSDE {
                        let (newKey, noiseKey) = MLX.split(key: rngKey)
                        rngKey = newKey
                        sacAgent.actor.resetNoise(key: noiseKey)
                    }
                }
                
                if i % 100 == 0 {
                    await Task.yield()
                }
            }
            
            sacAgent.updateNoSync()
            
            env = warmupEnv
            await MainActor.run { self.isWarmingUp = false }
            self.env = env
        }
        
        var lastUIUpdate = Date()
        let uiUpdateInterval: TimeInterval = renderEnabled ? 1.0 / 30.0 : 1.0 / 5.0
        
        while isTraining && episodesCompletedInRun < episodesPerRun {
            let result = env.reset()
            var state = preprocessObservation(result.obs)
            self.env = env
            
            if useSDE {
                let (newKey, noiseKey) = MLX.split(key: rngKey)
                rngKey = newKey
                sacAgent.actor.resetNoise(key: noiseKey)
            }
            
            await MainActor.run {
                self.currentStep = 0
                self.episodeReward = 0
                self.updateSnapshot()
            }
            
            var episodeRewardLocal: Double = 0
            var steps = 0
            var terminated = false
            var truncated = false
            
            while !terminated && !truncated && isTraining && steps < maxStepsPerEpisode {
                let action = sacAgent.chooseAction(state: state, key: &rngKey, deterministic: false)
                
                let stepResult = env.step(action)
                self.env = env
                
                let nextState = preprocessObservation(stepResult.obs)
                let reward = Float(stepResult.reward)
                terminated = stepResult.terminated
                truncated = stepResult.truncated
                
                sacAgent.store(
                    state: state,
                    action: action,
                    reward: reward,
                    nextState: nextState,
                    terminated: terminated
                )
                
                state = nextState
                episodeRewardLocal += stepResult.reward
                steps += 1
                totalSteps += 1

                if totalSteps >= warmupSteps && totalSteps % trainFreqSteps == 0 {
                    for _ in 0..<gradientStepsPerTrain {
                        sacAgent.updateNoSync()
                    }
                }

                if !turboMode {
                    if renderEnabled {
                        let currentSteps = steps
                        let currentReward = episodeRewardLocal
                        await MainActor.run {
                            self.currentStep = currentSteps
                            self.episodeReward = currentReward
                            self.updateSnapshot()
                        }
                        
                        let delayNs = UInt64(1_000_000_000 / targetFPS)
                        try? await Task.sleep(nanoseconds: delayNs)
                    } else {
                        let now = Date()
                        if now.timeIntervalSince(lastUIUpdate) >= uiUpdateInterval {
                            let currentSteps = steps
                            let currentReward = episodeRewardLocal
                            await MainActor.run {
                                self.currentStep = currentSteps
                                self.episodeReward = currentReward
                            }
                            lastUIUpdate = now
                        }
                    }
                } else if steps % 200 == 0 {
                    await Task.yield()
                }
            }
            
            let episodeCompleted = terminated || truncated
            if !episodeCompleted {
                await MainActor.run {
                    self.currentStep = 0
                    self.episodeReward = 0
                }
                break
            }
            
            let recentRewards = episodeMetrics.suffix(movingAverageWindow).map { $0.reward }
            let movingAvg = recentRewards.isEmpty ? episodeRewardLocal : recentRewards.reduce(0, +) / Double(recentRewards.count)
            
            let finalSteps = steps
            let finalReward = episodeRewardLocal
            let finalAlpha = Double(sacAgent.syncAlpha())
            
            await MainActor.run {
                let completedEpisodeNumber = self.loadedEpisodeCount + self.uncommittedEpisodeCount + 1
                
                let metrics = EpisodeMetrics(
                    episode: completedEpisodeNumber,
                    reward: episodeRewardLocal,
                    steps: finalSteps,
                    success: episodeRewardLocal >= 900,
                    averageTDError: 0,
                    averageLoss: nil,
                    averageMaxQ: 0,
                    epsilon: 0,
                    alpha: finalAlpha,
                    averageGradNorm: nil,
                    rewardMovingAverage: movingAvg
                )
                
                self.episodesCompletedInRun += 1
                self.currentStep = finalSteps
                self.episodeReward = finalReward
                self.totalReward += finalReward
                self.alpha = finalAlpha
                self.episodeMetrics.append(metrics)
                self.episodeCount += 1
            }
        }
        
        await MainActor.run {
            if self.isTraining {
                self.trainingCompletedNormally = true
            }
            self.stopTraining()
        }
    }
}


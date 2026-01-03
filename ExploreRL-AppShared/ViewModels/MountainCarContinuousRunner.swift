//
//  MountainCarContinuousRunner.swift
//

import SwiftUI
import Gymnazo
import MLX
import MLXNN

@MainActor
@Observable class MountainCarContinuousRunner: SavableEnvironmentRunner {
    var snapshot: MountainCarSnapshot?
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
    private var loadedBestReward: Double = 0
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
        let recent = episodeMetrics.suffix(50)
        return recent.map { $0.reward }.reduce(0, +) / Double(recent.count)
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -100
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .mountainCarContinuous }
    static var displayName: String { "Mountain Car Continuous" }
    static var algorithmName: String { "SAC" }
    static var icon: String { "car.side.fill" }
    static var accentColor: Color { .purple }
    static var category: EnvironmentCategory { .classicControl }
    
    var isRunning = false
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    
    var hiddenSize: Int = 256
    
    var learningRate: Double = 3e-4
    var gamma: Double = 0.99
    var tau: Double = 0.005
    
    var alpha: Double = 0.1
    var batchSize: Int = 256
    var bufferSize: Int = 50_000
    var warmupSteps: Int = 1000
    var maxStepsPerEpisode: Int = 999
    var learnedStd: Bool = true
    var useGSDE: Bool = false
    var sdeSampleFreq: Int = -1
    
    var autoAlpha: Bool = true
    var initAlpha: Double = 1.0
    var alphaLr: Double = 0.0003
    var trainFreqSteps: Int = 1
    var gradientStepsPerTrain: Int = 1
    
    var goalVelocity: Double = 0.0
    
    var position: Float = -0.5
    var velocity: Float = 0.0
    
    private var env: (any Env<MLXArray, MLXArray>)?
    private var rngKey: MLXArray
    private var agent: MountainCarContinuousSAC?
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
            "goal_velocity": goalVelocity
        ]
        if renderEnabled {
            kwargs["render_mode"] = "human"
        }
        
        guard let madeEnv = Gymnazo.make(
            "MountainCarContinuous",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            print("Failed to create MountainCarContinuous environment")
            return
        }
        
        self.env = madeEnv
        _ = self.env?.reset()
        updateSnapshot()
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(0)
        }
        
        let shouldRecreateAgent: Bool
        if let existing = agent {
            shouldRecreateAgent =
                existing.actor.learnedStd != learnedStd ||
                existing.actor.useGSDE != useGSDE ||
                existing.autoTuneAlpha != autoAlpha ||
                existing.hiddenSize != hiddenSize
        } else {
            shouldRecreateAgent = true
        }
        
        if shouldRecreateAgent {
            let entCoefMode: EntropyCoefficientMode
            if autoAlpha {
                entCoefMode = .auto(initAlpha: Float(initAlpha), alphaLr: Float(alphaLr), targetEntropy: nil)
            } else {
                entCoefMode = .fixed(alpha: Float(alpha))
            }
            
            agent = MountainCarContinuousSAC(
                hiddenSize: hiddenSize,
                learningRate: Float(learningRate),
                gamma: Float(gamma),
                tau: Float(tau),
                batchSize: batchSize,
                bufferSize: bufferSize,
                learnedStd: learnedStd,
                entCoefMode: entCoefMode,
                useGSDE: useGSDE
            )
        }
        
        episodeCount = 1
        currentStep = 0
        totalReward = 0
        episodeReward = 0
    }
    
    private func updateSnapshot() {
        if let mc = self.env?.unwrapped as? MountainCarContinuous {
            self.snapshot = mc.currentSnapshot
            self.position = snapshot?.position ?? -0.5
            self.velocity = snapshot?.velocity ?? 0.0
        }
    }
    
    func reset() {
        stopTraining()
        stopRunning()
        accumulatedTrainingTimeSeconds = 0
        trainingSessionStartDate = nil
        agent = nil
        episodeMetrics = []
        committedEpisodeMetricsCount = 0
        totalSteps = 0
        hiddenSize = 256
        learningRate = 3e-4
        gamma = 0.99
        tau = 0.005
        alpha = 0.1
        batchSize = 256
        bufferSize = 50_000
        warmupSteps = 1000
        learnedStd = true
        useGSDE = false
        sdeSampleFreq = -1
        autoAlpha = true
        initAlpha = 1.0
        alphaLr = 0.0003
        trainFreqSteps = 1
        gradientStepsPerTrain = 1
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = 0
        trainingCompletedNormally = false
        setupEnvironment()
    }
    
    func startTraining() {
        guard !isTraining else { return }
        guard !TrainingState.shared.isTraining else { return }
        
        isTraining = true
        if trainingSessionStartDate == nil {
            trainingSessionStartDate = Date()
        }
        trainingCompletedNormally = false
        if loadedAgentId != nil {
            hasTrainedSinceLoad = true
        }
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
        
        let saved = try AgentStorage.shared.saveMountainCarContinuousAgentVmap(
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
                "hiddenSize": Double(hiddenSize),
                "learningRate": learningRate,
                "gamma": gamma,
                "tau": tau,
                "alpha": alpha,
                "learnedStd": learnedStd ? 1.0 : 0.0,
                "useGSDE": useGSDE ? 1.0 : 0.0,
                "sdeSampleFreq": Double(sdeSampleFreq),
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
                "goal_velocity": "\(goalVelocity)"
            ],
            hiddenSize: hiddenSize
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
        
        try AgentStorage.shared.updateMountainCarContinuousAgentVmap(
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
                "hiddenSize": Double(hiddenSize),
                "learningRate": learningRate,
                "gamma": gamma,
                "tau": tau,
                "alpha": alpha,
                "learnedStd": learnedStd ? 1.0 : 0.0,
                "useGSDE": useGSDE ? 1.0 : 0.0,
                "sdeSampleFreq": Double(sdeSampleFreq),
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
        guard savedAgent.environmentType == .mountainCarContinuous else {
            throw AgentStorageError.wrongEnvironmentType
        }
        
        stopTraining()
        accumulatedTrainingTimeSeconds = savedAgent.trainingTimeSeconds ?? 0
        trainingSessionStartDate = nil
        
        if let lr = savedAgent.hyperparameters["learningRate"] { learningRate = lr }
        if let g = savedAgent.hyperparameters["gamma"] { gamma = g }
        if let t = savedAgent.hyperparameters["tau"] { tau = t }
        if let a = savedAgent.hyperparameters["alpha"] { alpha = a }
        
        if let hs = savedAgent.hyperparameters["hiddenSize"] {
            hiddenSize = max(1, Int(hs.rounded()))
        } else if let actorArch = savedAgent.networkArchitecture?.first(where: { $0.networkType == "actor" }),
                  let hs = actorArch.hiddenSizes.first {
            hiddenSize = hs
        } else {
            hiddenSize = 256
        }
        if let ls = savedAgent.hyperparameters["learnedStd"] { learnedStd = ls > 0.5 }
        else if let sde = savedAgent.hyperparameters["useSDE"] { learnedStd = sde > 0.5 }
        
        if let ug = savedAgent.hyperparameters["useGSDE"] {
            useGSDE = ug > 0.5
        } else {
            useGSDE = false
        }
        if let sf = savedAgent.hyperparameters["sdeSampleFreq"] {
            sdeSampleFreq = Int(sf.rounded())
        }
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
        if let gv = savedAgent.environmentConfig["goal_velocity"],
           let gvVal = Double(gv) {
            goalVelocity = gvVal
        }
        
        agent = nil
        setupEnvironment()
        
        let weightsDict = try AgentStorage.shared.loadSACVmapWeights(for: savedAgent)
        
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
    
    
    func step(action: Float) {
        guard var env = self.env else { return }
        
        let actionArray = MLXArray(action).reshaped([1])
        let result = env.step(actionArray)
        self.env = env
        
        currentStep += 1
        episodeReward += result.reward
        totalReward += result.reward
        
        updateSnapshot()
        
        if result.terminated || result.truncated {
            episodeCount += 1
            currentStep = 0
            episodeReward = 0
            _ = env.reset()
            self.env = env
            updateSnapshot()
        }
    }
    
    func runRandomEpisode() {
        guard !isRunning else { return }
        isRunning = true
        
        Task.detached { [weak self] in
            await self?.runRandomEpisodeLoop()
        }
    }
    
    private func runRandomEpisodeLoop() async {
        guard var env = self.env else { return }
        
        _ = env.reset()
        self.env = env
        
        await MainActor.run {
            self.currentStep = 0
            self.episodeReward = 0
            self.updateSnapshot()
        }
        
        var terminated = false
        var truncated = false
        var steps = 0
        
        while !terminated && !truncated && isRunning && steps < maxStepsPerEpisode {
            let (newKey, actionKey) = MLX.split(key: rngKey)
            rngKey = newKey
            let range: Range<Float> = (-1.0 as Float)..<(1.0 as Float)
            let actionArray = MLX.uniform(range, [1], key: actionKey)
            
            let result = env.step(actionArray)
            self.env = env
            
            terminated = result.terminated
            truncated = result.truncated
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward += result.reward
                self.totalReward += result.reward
                self.updateSnapshot()
            }
            
            if renderEnabled {
                let delayNs = UInt64(1_000_000_000 / self.targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        await MainActor.run {
            self.isRunning = false
            if terminated {
                self.episodeCount += 1
            }
        }
    }
    
    
    private func trainingLoop() async {
        guard var env = self.env else { return }
        
        guard let _ = env.observation_space as? Box,
              let _ = env.action_space as? Box,
              let sacAgent = self.agent else {
            await MainActor.run { self.stopTraining() }
            return
        }
        
        var episodesCompleted = 0
        
        if totalSteps < warmupSteps {
            await MainActor.run { self.isWarmingUp = true }
            
            var warmupEnv = env
            let warmupResult = warmupEnv.reset()
            var warmupState = warmupResult.obs
            
            let samplesToCollect = warmupSteps - totalSteps
            
            for i in 0..<samplesToCollect {
                let (newKey, actionKey) = MLX.split(key: rngKey)
                rngKey = newKey
                let range: Range<Float> = MountainCarContinuousSAC.actionLow..<MountainCarContinuousSAC.actionHigh
                let action = MLX.uniform(range, [MountainCarContinuousSAC.actionCount], key: actionKey)
                let stepResult = warmupEnv.step(action)
                
                sacAgent.store(
                    state: warmupState,
                    action: action,
                    reward: Float(stepResult.reward),
                    nextState: stepResult.obs,
                    terminated: stepResult.terminated
                )
                
                warmupState = stepResult.obs
                totalSteps += 1
                
                if stepResult.terminated || stepResult.truncated {
                    let resetResult = warmupEnv.reset()
                    warmupState = resetResult.obs
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
        
        while isTraining && episodesCompleted < episodesPerRun {
            let result = env.reset()
            var state = result.obs
            self.env = env
            
            if useGSDE {
                sacAgent.actor.resetNoise(key: &rngKey)
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
                if useGSDE, sdeSampleFreq > 0, steps > 0, (steps % sdeSampleFreq == 0) {
                    sacAgent.actor.resetNoise(key: &rngKey)
                }
                
                let action = sacAgent.chooseAction(state: state, key: &rngKey, deterministic: false)
                
                let stepResult = env.step(action)
                self.env = env
                
                let nextState = stepResult.obs
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
                
                let now = Date()
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
                } else if now.timeIntervalSince(lastUIUpdate) >= uiUpdateInterval {
                    let currentSteps = steps
                    let currentReward = episodeRewardLocal
                    await MainActor.run {
                        self.currentStep = currentSteps
                        self.episodeReward = currentReward
                    }
                    lastUIUpdate = now
                }
                
                if !renderEnabled && steps % 50 == 0 {
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
            
            episodesCompleted += 1
            
            let recentRewards = episodeMetrics.suffix(50).map { $0.reward }
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
                    success: terminated,
                    averageTDError: 0,
                    averageLoss: nil,
                    averageMaxQ: 0,
                    epsilon: 0,
                    alpha: finalAlpha,
                    averageGradNorm: nil,
                    rewardMovingAverage: movingAvg
                )
                
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

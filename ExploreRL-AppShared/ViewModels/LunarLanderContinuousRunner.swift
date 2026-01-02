//
//  LunarLanderContinuousRunner.swift
//

import SwiftUI
import Gymnazo
import MLX
import MLXNN

@MainActor
@Observable class LunarLanderContinuousRunner: SavableEnvironmentRunner {
    var snapshot: LunarLanderSnapshot?
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
    private var loadedBestReward: Double = -500
    private var trainingCompletedNormally = false
    
    private(set) var accumulatedTrainingTimeSeconds: TimeInterval = 0
    private(set) var trainingSessionStartDate: Date? = nil
    
    var totalTrainingTimeSeconds: TimeInterval {
        accumulatedTrainingTimeSeconds + (trainingSessionStartDate.map { Date().timeIntervalSince($0) } ?? 0)
    }
    
    var canResume: Bool {
        return agent != nil && episodeCount > 1 && !trainingCompletedNormally
    }
    
    var totalEpisodesTrained: Int {
        return loadedEpisodeCount + episodeMetrics.count
    }
    
    var averageReward: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recent = episodeMetrics.suffix(movingAverageWindow)
        return recent.map { $0.reward }.reduce(0, +) / Double(recent.count)
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -500
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .lunarLanderContinuous }
    static var displayName: String { "Lunar Lander Continuous" }
    static var algorithmName: String { "SAC" }
    static var icon: String { "airplane.circle.fill" }
    static var accentColor: Color { .teal }
    static var category: EnvironmentCategory { .box2d }
    
    var isRunning = false
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    var movingAverageWindow = 100
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    
    var learningRate: Double = Double(LunarLanderContinuousSAC.Defaults.learningRate)
    var gamma: Double = Double(LunarLanderContinuousSAC.Defaults.gamma)
    var tau: Double = Double(LunarLanderContinuousSAC.Defaults.tau)
    var alpha: Double = Double(LunarLanderContinuousSAC.Defaults.alpha)
    var batchSize: Int = LunarLanderContinuousSAC.Defaults.batchSize
    var bufferSize: Int = LunarLanderContinuousSAC.Defaults.bufferSize
    var warmupSteps: Int = 1000
    var maxStepsPerEpisode: Int = 1000
    
    var envGravity: Double = -10.0
    var enableWind: Bool = false
    var windPower: Double = 15.0
    var turbulencePower: Double = 1.5
    
    private var episodesCompletedInRun: Int = 0
    private var env: (any Env<MLXArray, MLXArray>)?
    private var rngKey: MLXArray
    private var agent: LunarLanderContinuousSAC?
    private var totalSteps: Int = 0
    
    var isWarmingUp: Bool = false
    var warmupProgress: Double {
        guard warmupSteps > 0 else { return 1.0 }
        return min(1.0, Double(totalSteps) / Double(warmupSteps))
    }
    
    var landingSuccessRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recent = episodeMetrics.suffix(movingAverageWindow)
        let successes = recent.filter { $0.reward >= 200 }.count
        return Double(successes) / Double(recent.count)
    }
    
    init() {
        self.rngKey = MLX.key(0)
        setupEnvironment()
    }
    
    func setupEnvironment() {
        var kwargs: [String: Any] = [
            "gravity": envGravity,
            "enable_wind": enableWind,
            "wind_power": windPower,
            "turbulence_power": turbulencePower
        ]
        if renderEnabled {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "LunarLanderContinuous",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            print("Failed to create LunarLanderContinuous environment")
            return
        }
        
        let _ = env.reset()
        
        if renderEnabled {
            self.snapshot = env.render() as? LunarLanderSnapshot
        } else {
            self.snapshot = nil
        }
        
        self.env = env
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(0)
        }
        
        if agent == nil {
            agent = LunarLanderContinuousSAC(
                learningRate: Float(learningRate),
                gamma: Float(gamma),
                tau: Float(tau),
                alpha: Float(alpha),
                batchSize: batchSize,
                bufferSize: bufferSize
            )
        }
        
        episodeMetrics.removeAll()
        episodeCount = 1
        currentStep = 0
        totalReward = 0
        episodeReward = 0
        totalSteps = 0
        episodesCompletedInRun = 0
    }
    
    private func updateSnapshot() {
        if renderEnabled {
            self.snapshot = self.env?.render() as? LunarLanderSnapshot
        }
    }
    
    func reset() {
        stopTraining()
        stopRunning()
        accumulatedTrainingTimeSeconds = 0
        trainingSessionStartDate = nil
        agent = nil
        alpha = Double(LunarLanderContinuousSAC.Defaults.alpha)
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = -500
        trainingCompletedNormally = false
        setupEnvironment()
    }
    
    func resetToDefaults() {
        learningRate = Double(LunarLanderContinuousSAC.Defaults.learningRate)
        gamma = Double(LunarLanderContinuousSAC.Defaults.gamma)
        tau = Double(LunarLanderContinuousSAC.Defaults.tau)
        alpha = Double(LunarLanderContinuousSAC.Defaults.alpha)
        batchSize = LunarLanderContinuousSAC.Defaults.batchSize
        bufferSize = LunarLanderContinuousSAC.Defaults.bufferSize
        
        warmupSteps = 1000
        renderEnabled = TrainingDefaults.renderEnabled
        episodesPerRun = TrainingDefaults.episodesPerRun
        episodesCompletedInRun = 0
        useSeed = TrainingDefaults.useSeed
        seed = TrainingDefaults.seed
        maxStepsPerEpisode = 1000
        targetFPS = TrainingDefaults.targetFPS
        turboMode = TrainingDefaults.turboMode
        envGravity = -10.0
        enableWind = false
        windPower = 15.0
        turbulencePower = 1.5
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
        
        let saved = try AgentStorage.shared.saveLunarLanderContinuousAgent(
            name: name,
            actor: agent.actor,
            qEnsemble: agent.qEnsemble,
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
                "batchSize": Double(batchSize),
                "bufferSize": Double(bufferSize),
                "warmupSteps": Double(warmupSteps),
                "totalSteps": Double(totalSteps)
            ],
            environmentConfig: [
                "maxStepsPerEpisode": "\(maxStepsPerEpisode)",
                "gravity": "\(envGravity)",
                "enable_wind": enableWind ? "true" : "false",
                "wind_power": "\(windPower)",
                "turbulence_power": "\(turbulencePower)"
            ]
        )
        
        loadedAgentId = saved.id
        loadedAgentName = saved.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = totalEpisodesTrained
        loadedBestReward = combinedBestReward
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func updateAgent(id: UUID, name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        try AgentStorage.shared.updateLunarLanderContinuousAgent(
            id: id,
            newName: name,
            actor: agent.actor,
            qEnsemble: agent.qEnsemble,
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
                "batchSize": Double(batchSize),
                "bufferSize": Double(bufferSize),
                "warmupSteps": Double(warmupSteps),
                "totalSteps": Double(totalSteps)
            ]
        )
        
        loadedAgentName = name
        hasTrainedSinceLoad = false
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .lunarLanderContinuous else {
            throw AgentStorageError.wrongEnvironmentType
        }
        
        stopTraining()
        accumulatedTrainingTimeSeconds = savedAgent.trainingTimeSeconds ?? 0
        trainingSessionStartDate = nil
        
        if let lr = savedAgent.hyperparameters["learningRate"] { learningRate = lr }
        if let g = savedAgent.hyperparameters["gamma"] { gamma = g }
        if let t = savedAgent.hyperparameters["tau"] { tau = t }
        if let a = savedAgent.hyperparameters["alpha"] { alpha = a }
        if let bs = savedAgent.hyperparameters["batchSize"] { batchSize = Int(bs) }
        if let buf = savedAgent.hyperparameters["bufferSize"] { bufferSize = Int(buf) }
        if let wSteps = savedAgent.hyperparameters["warmupSteps"] { warmupSteps = Int(wSteps) }
        if let tSteps = savedAgent.hyperparameters["totalSteps"] { totalSteps = Int(tSteps) }
        
        if let maxSteps = savedAgent.environmentConfig["maxStepsPerEpisode"],
           let steps = Int(maxSteps) {
            maxStepsPerEpisode = steps
        }
        if let grav = savedAgent.environmentConfig["gravity"],
           let gravVal = Double(grav) {
            envGravity = gravVal
        }
        if let wind = savedAgent.environmentConfig["enable_wind"] {
            enableWind = wind == "true"
        }
        if let wp = savedAgent.environmentConfig["wind_power"],
           let wpVal = Double(wp) {
            windPower = wpVal
        }
        if let tp = savedAgent.environmentConfig["turbulence_power"],
           let tpVal = Double(tp) {
            turbulencePower = tpVal
        }
        
        agent = nil
        setupEnvironment()
        
        let weightsDict = try AgentStorage.shared.loadLunarLanderContinuousWeights(for: savedAgent)
        
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
        
        eval(agent.actor, agent.qEnsemble, agent.qEnsembleTarget)
        
        episodeMetrics = []
        episodeCount = savedAgent.episodesTrained + 1
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
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
            let actionArray = MLX.uniform(range, [2], key: actionKey)
            
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
        
        if totalSteps < warmupSteps {
            await MainActor.run { self.isWarmingUp = true }
            
            var warmupEnv = env
            let warmupResult = warmupEnv.reset()
            var warmupState = warmupResult.obs
            
            let samplesToCollect = warmupSteps - totalSteps
            
            for i in 0..<samplesToCollect {
                let (newKey, actionKey) = MLX.split(key: rngKey)
                rngKey = newKey
                let range: Range<Float> = LunarLanderContinuousSAC.actionLow..<LunarLanderContinuousSAC.actionHigh
                let action = MLX.uniform(range, [LunarLanderContinuousSAC.actionCount], key: actionKey)
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
        
        while isTraining && episodesCompletedInRun < episodesPerRun {
            let result = env.reset()
            var state = result.obs
            self.env = env
            
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

                if totalSteps >= warmupSteps {
                    sacAgent.updateNoSync()
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
                let completedEpisodeNumber = loadedEpisodeCount + episodeMetrics.count + 1
                
                let metrics = EpisodeMetrics(
                    episode: completedEpisodeNumber,
                    reward: episodeRewardLocal,
                    steps: finalSteps,
                    success: episodeRewardLocal >= 200,
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

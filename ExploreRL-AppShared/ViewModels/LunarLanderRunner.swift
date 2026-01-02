//
//  LunarLanderRunner.swift
//

import Foundation
import Gymnazo
import SwiftUI
import MLX
import MLXNN

@MainActor
@Observable class LunarLanderRunner: SavableEnvironmentRunner {
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
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { $0.reward }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -500
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .lunarLander }
    static var displayName: String { "Lunar Lander" }
    static var algorithmName: String { "DQN" }
    static var icon: String { "airplane" }
    static var accentColor: Color { .blue }
    static var category: EnvironmentCategory { .box2d }
    
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    var movingAverageWindow = 100
    
    var learningRate: Double = Double(LunarLanderDQN.Defaults.learningRate)
    var gamma: Double = Double(LunarLanderDQN.Defaults.gamma)
    var epsilon: Double = Double(LunarLanderDQN.Defaults.epsilonStart)
    var epsilonDecaySteps: Int = LunarLanderDQN.Defaults.epsilonDecaySteps
    var epsilonMin: Double = Double(LunarLanderDQN.Defaults.epsilonEnd)
    var batchSize: Int = LunarLanderDQN.Defaults.batchSize
    var targetUpdateFrequency: Int = LunarLanderDQN.Defaults.targetUpdateFrequency
    var warmupSteps: Int = 1000
    var gradClipNorm: Double = Double(LunarLanderDQN.Defaults.gradClipNorm)
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    var maxStepsPerEpisode: Int = 1000
    
    var envGravity: Double = -10.0
    var enableWind: Bool = false
    var windPower: Double = 15.0
    var turbulencePower: Double = 1.5
    
    var earlyStopEnabled: Bool = TrainingDefaults.earlyStopEnabled
    var earlyStopWindow: Int = 100
    var earlyStopRewardThreshold: Double = 200.0
    
    var clipReward: Bool = TrainingDefaults.clipReward
    var clipRewardMin: Double = TrainingDefaults.clipRewardMin
    var clipRewardMax: Double = TrainingDefaults.clipRewardMax
    
    private var episodesCompletedInRun: Int = 0
    private var env: (any Env<MLXArray, Int>)?
    private var rngKey: MLXArray
    private var agent: LunarLanderDQN?
    private var totalSteps: Int = 0
    
    var isWarmingUp: Bool = false
    var warmupProgress: Double {
        guard warmupSteps > 0 else { return 1.0 }
        return min(1.0, Double(totalSteps) / Double(warmupSteps))
    }
    
    var landingSuccessRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let successes = recentEpisodes.filter { $0.reward >= 200 }.count
        return Double(successes) / Double(recentEpisodes.count)
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
            "LunarLander",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: kwargs
        ) as? any Env<MLXArray, Int> else {
            print("Failed to create LunarLander environment")
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
        
        self.agent = LunarLanderDQN(
            learningRate: Float(learningRate),
            gamma: Float(gamma),
            epsilonStart: Float(epsilon),
            epsilonEnd: Float(epsilonMin),
            epsilonDecaySteps: epsilonDecaySteps,
            targetUpdateFrequency: targetUpdateFrequency,
            batchSize: batchSize,
            bufferCapacity: 100_000,
            gradClipNorm: Float(gradClipNorm)
        )
        
        episodeMetrics.removeAll()
        committedEpisodeMetricsCount = 0
        totalReward = 0
        episodeCount = 1
        currentStep = 0
        episodeReward = 0
        totalSteps = 0
        episodesCompletedInRun = 0
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
        TrainingState.shared.startTraining(environment: Self.displayName)
        
        Task.detached { [weak self] in
            await self?.runTrainingLoop()
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
    
    func reset() {
        stopTraining()
        accumulatedTrainingTimeSeconds = 0
        trainingSessionStartDate = nil
        
        epsilon = Double(LunarLanderDQN.Defaults.epsilonStart)
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = -500
        trainingCompletedNormally = false
        committedEpisodeMetricsCount = 0
        
        setupEnvironment()
    }
    
    func resetToDefaults() {
        learningRate = Double(LunarLanderDQN.Defaults.learningRate)
        gamma = Double(LunarLanderDQN.Defaults.gamma)
        epsilon = Double(LunarLanderDQN.Defaults.epsilonStart)
        epsilonDecaySteps = LunarLanderDQN.Defaults.epsilonDecaySteps
        epsilonMin = Double(LunarLanderDQN.Defaults.epsilonEnd)
        batchSize = LunarLanderDQN.Defaults.batchSize
        targetUpdateFrequency = LunarLanderDQN.Defaults.targetUpdateFrequency
        gradClipNorm = Double(LunarLanderDQN.Defaults.gradClipNorm)
        
        warmupSteps = 1000
        renderEnabled = TrainingDefaults.renderEnabled
        episodesPerRun = TrainingDefaults.episodesPerRun
        episodesCompletedInRun = 0
        useSeed = TrainingDefaults.useSeed
        seed = TrainingDefaults.seed
        maxStepsPerEpisode = 1000
        earlyStopEnabled = TrainingDefaults.earlyStopEnabled
        earlyStopWindow = 100
        earlyStopRewardThreshold = 200.0
        clipReward = TrainingDefaults.clipReward
        clipRewardMin = TrainingDefaults.clipRewardMin
        clipRewardMax = TrainingDefaults.clipRewardMax
        targetFPS = TrainingDefaults.targetFPS
        turboMode = TrainingDefaults.turboMode
        envGravity = -10.0
        enableWind = false
        windPower = 15.0
        turbulencePower = 1.5
    }
    
    func saveAgent(name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        let saved = try AgentStorage.shared.saveLunarLanderAgent(
            name: name,
            policyNetwork: agent.policyNetwork,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            epsilon: epsilon,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "learningRate": learningRate,
                "gamma": gamma,
                "epsilon": epsilon,
                "epsilonMin": epsilonMin,
                "epsilonDecaySteps": Double(epsilonDecaySteps),
                "targetUpdateFrequency": Double(targetUpdateFrequency),
                "batchSize": Double(batchSize),
                "gradClipNorm": gradClipNorm,
                "warmupSteps": Double(warmupSteps),
                "explorationSteps": Double(agent.currentExplorationSteps),
                "trainingSteps": Double(agent.currentSteps)
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
        committedEpisodeMetricsCount = episodeMetrics.count
        loadedBestReward = combinedBestReward
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func updateAgent(id: UUID, name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        try AgentStorage.shared.updateLunarLanderAgent(
            id: id,
            newName: name,
            policyNetwork: agent.policyNetwork,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            epsilon: epsilon,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "learningRate": learningRate,
                "gamma": gamma,
                "epsilon": epsilon,
                "epsilonMin": epsilonMin,
                "epsilonDecaySteps": Double(epsilonDecaySteps),
                "targetUpdateFrequency": Double(targetUpdateFrequency),
                "batchSize": Double(batchSize),
                "gradClipNorm": gradClipNorm,
                "warmupSteps": Double(warmupSteps),
                "explorationSteps": Double(agent.currentExplorationSteps),
                "trainingSteps": Double(agent.currentSteps)
            ]
        )
        
        loadedAgentName = name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = totalEpisodesTrained
        committedEpisodeMetricsCount = episodeMetrics.count
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .lunarLander else {
            throw AgentStorageError.wrongEnvironmentType
        }
        
        stopTraining()
        accumulatedTrainingTimeSeconds = savedAgent.trainingTimeSeconds ?? 0
        trainingSessionStartDate = nil
        
        if let lr = savedAgent.hyperparameters["learningRate"] { learningRate = lr }
        if let g = savedAgent.hyperparameters["gamma"] { gamma = g }
        if let eps = savedAgent.hyperparameters["epsilon"] { epsilon = eps }
        if let epsMin = savedAgent.hyperparameters["epsilonMin"] { epsilonMin = epsMin }
        if let decaySteps = savedAgent.hyperparameters["epsilonDecaySteps"] { epsilonDecaySteps = Int(decaySteps) }
        if let t = savedAgent.hyperparameters["targetUpdateFrequency"] { targetUpdateFrequency = Int(t) }
        if let bs = savedAgent.hyperparameters["batchSize"] { batchSize = Int(bs) }
        if let gcn = savedAgent.hyperparameters["gradClipNorm"] { gradClipNorm = gcn }
        if let wSteps = savedAgent.hyperparameters["warmupSteps"] { warmupSteps = Int(wSteps) }
        
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
        
        setupEnvironment()
        
        let weightsDict = try AgentStorage.shared.loadLunarLanderWeights(for: savedAgent)
        
        guard let agent = self.agent else {
            throw AgentStorageError.dataCorrupted
        }
        
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        let newParams = NestedDictionary<String, MLXArray>.unflattened(weightsTuples)
        agent.policyNetwork.update(parameters: newParams)
        agent.targetNetwork.update(parameters: newParams)
        eval(agent.policyNetwork.parameters())
        eval(agent.targetNetwork.parameters())
        
        if let explorationSteps = savedAgent.hyperparameters["explorationSteps"] {
            agent.setExplorationSteps(Int(explorationSteps))
        }
        if let trainingSteps = savedAgent.hyperparameters["trainingSteps"] {
            agent.setSteps(Int(trainingSteps))
        }
        
        episodeMetrics = []
        committedEpisodeMetricsCount = 0
        episodeCount = savedAgent.episodesTrained + 1
        episodesCompletedInRun = 0
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
    }
    
    private func getCurrentSnapshot(from environment: any Env<MLXArray, Int>) -> LunarLanderSnapshot {
        guard renderEnabled else { return .zero }
        // Use render() which properly accesses the current state through the wrapper chain
        if let snapshot = environment.render() as? LunarLanderSnapshot {
            return snapshot
        }
        return .zero
    }
    
    private func runTrainingLoop() async {
        var lastUIUpdate = Date()
        let uiUpdateInterval: TimeInterval = renderEnabled ? 1.0 / 30.0 : 1.0 / 5.0
        
        guard var env = self.env, let agent = self.agent else { return }
        guard let actSpace = env.action_space as? Discrete else { return }
        
        if warmupSteps > 0 && totalSteps < warmupSteps {
            await MainActor.run { self.isWarmingUp = true }
            
            var warmupEnv = env
            let warmupResult = warmupEnv.reset()
            var warmupState = warmupResult.obs
            
            let samplesToCollect = warmupSteps - totalSteps
            
            for i in 0..<samplesToCollect {
                let (newKey, sampleKey) = MLX.split(key: rngKey)
                rngKey = newKey
                let randomAction = actSpace.sample(key: sampleKey)
                let stepResult = warmupEnv.step(randomAction)
                
                agent.store(
                    state: warmupState,
                    action: MLXArray(Int32(randomAction)).reshaped([1, 1]),
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
            
            _ = agent.update()
            
            env = warmupEnv
            self.env = env
            await MainActor.run { self.isWarmingUp = false }
        }
        
        while isTraining {
            guard var env = self.env, let agent = self.agent else { break }
            
            let resetResult = env.reset()
            self.env = env
            var state = resetResult.obs
            
            var terminated = false
            var truncated = false
            var steps = 0
            var episodeRewardLocal = 0.0
            var totalLossArray = MLXArray(Float32(0.0))
            var totalMeanQArray = MLXArray(Float32(0.0))
            var totalGradNormArray = MLXArray(Float32(0.0))
            var totalTdErrorArray = MLXArray(Float32(0.0))
            var lossCount = 0
            
            if !turboMode || episodeCount % 10 == 0 {
                await MainActor.run {
                    self.currentStep = 0
                    self.episodeReward = 0
                }
            }
            
            while !terminated && !truncated {
                if !isTraining { break }
                
                var keyForAction = self.rngKey
                
                guard let actionSpace = env.action_space as? Discrete else { break }
                
                let action = agent.chooseAction(
                    state: state,
                    actionSpace: actionSpace,
                    key: &keyForAction
                ).item(Int.self)
                self.rngKey = keyForAction
                
                let result = env.step(action)
                self.env = env
                
                terminated = result.terminated
                truncated = result.truncated
                
                steps += 1
                let usedReward = clipReward ? min(max(result.reward, clipRewardMin), clipRewardMax) : result.reward
                episodeRewardLocal += usedReward
                
                let nextState = result.obs
                
                agent.store(
                    state: state,
                    action: MLXArray(Int32(action)),
                    reward: Float(usedReward),
                    nextState: nextState,
                    terminated: terminated
                )
                
                totalSteps += 1

                if totalSteps >= warmupSteps {
                    if let (loss, meanQ, gradNorm, tdError) = agent.updateArrays() {
                        totalLossArray = totalLossArray + loss
                        totalMeanQArray = totalMeanQArray + meanQ
                        totalGradNormArray = totalGradNormArray + gradNorm
                        totalTdErrorArray = totalTdErrorArray + tdError
                        lossCount += 1
                    }
                }
                state = nextState
                
                if !turboMode {
                    let currentS = steps
                    let currentR = episodeRewardLocal
                    if renderEnabled {
                        let snap = getCurrentSnapshot(from: env)
                        await MainActor.run {
                            self.snapshot = snap
                            self.currentStep = currentS
                            self.episodeReward = currentR
                        }
                        let delayNs = UInt64(1_000_000_000 / self.targetFPS)
                        try? await Task.sleep(nanoseconds: delayNs)
                    } else {
                        let now = Date()
                        if now.timeIntervalSince(lastUIUpdate) >= uiUpdateInterval {
                            await MainActor.run {
                                self.currentStep = currentS
                                self.episodeReward = currentR
                            }
                            lastUIUpdate = now
                        }
                    }
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
            
            let finalReward = episodeRewardLocal
            let finalSteps = steps
            let avgLoss: Double? = lossCount > 0 ? Double((totalLossArray / Float(lossCount)).item(Float.self)) : nil
            let avgMaxQ: Double = lossCount > 0 ? Double((totalMeanQArray / Float(lossCount)).item(Float.self)) : 0.0
            let avgGradNorm: Double? = lossCount > 0 ? Double((totalGradNormArray / Float(lossCount)).item(Float.self)) : nil
            let avgTdError: Double? = lossCount > 0 ? Double((totalTdErrorArray / Float(lossCount)).item(Float.self)) : nil
            
            if episodeCount % 50 == 0 {
                GPU.clearCache()
            }
            
            await MainActor.run {
                self.episodesCompletedInRun += 1
                self.totalReward += finalReward
                if let agent = self.agent {
                    self.epsilon = Double(agent.epsilon)
                }
                
                let window = max(1, min(self.movingAverageWindow, self.episodeMetrics.count + 1))
                let recentRewards = self.episodeMetrics.suffix(window - 1).map { $0.reward }
                let rewardSum = recentRewards.reduce(0, +) + finalReward
                let rewardMovingAverage = rewardSum / Double(window)
                
                let completedEpisodeNumber = self.loadedEpisodeCount + self.uncommittedEpisodeCount + 1
                
                let metric = EpisodeMetrics(
                    episode: completedEpisodeNumber,
                    reward: finalReward,
                    steps: finalSteps,
                    success: finalReward >= 200,
                    averageTDError: avgTdError ?? 0,
                    averageLoss: avgLoss,
                    averageMaxQ: avgMaxQ,
                    epsilon: self.epsilon,
                    alpha: nil,
                    averageGradNorm: avgGradNorm,
                    rewardMovingAverage: rewardMovingAverage
                )
                self.episodeMetrics.append(metric)
                
                self.episodeCount += 1
            }
            
            if earlyStopEnabled {
                let window = max(1, earlyStopWindow)
                let recent = self.episodeMetrics.suffix(window)
                if !recent.isEmpty {
                    let avg = recent.map { $0.reward }.reduce(0, +) / Double(recent.count)
                    if avg >= earlyStopRewardThreshold {
                        await MainActor.run {
                            self.trainingCompletedNormally = true
                            self.stopTraining()
                        }
                        break
                    }
                }
            }
            
            if episodesPerRun > 0 && episodesCompletedInRun >= episodesPerRun {
                await MainActor.run {
                    self.trainingCompletedNormally = true
                    self.stopTraining()
                }
                break
            }
            
            if turboMode {
                await Task.yield()
            }
        }
        
        await MainActor.run {
            if self.isTraining {
                self.stopTraining()
            }
        }
    }
}

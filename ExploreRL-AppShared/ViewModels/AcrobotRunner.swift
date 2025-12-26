//
//  AcrobotRunner.swift
//

import Foundation
import Gymnazo
import SwiftUI
import MLX
import MLXNN

@MainActor
@Observable class AcrobotRunner: SavableEnvironmentRunner {
    var snapshot: AcrobotSnapshot?
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
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { $0.reward }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -500
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .acrobot }
    static var displayName: String { "Acrobot" }
    static var algorithmName: String { "DQN" }
    static var icon: String { "figure.flexibility" }
    static var accentColor: Color { .red }
    static var category: EnvironmentCategory { .classicControl }
    
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    var movingAverageWindow = 50
    
    var learningRate: Double = Double(AcrobotDQN.Defaults.learningRate)
    var gamma: Double = Double(AcrobotDQN.Defaults.gamma)
    var epsilon: Double = Double(AcrobotDQN.Defaults.epsilonStart)
    var epsilonDecaySteps: Int = AcrobotDQN.Defaults.epsilonDecaySteps
    var epsilonMin: Double = Double(AcrobotDQN.Defaults.epsilonEnd)
    var batchSize: Int = AcrobotDQN.Defaults.batchSize
    var targetUpdateFrequency: Int = AcrobotDQN.Defaults.targetUpdateFrequency
    var warmupSteps: Int = TrainingDefaults.warmupSteps
    var gradClipNorm: Double = Double(AcrobotDQN.Defaults.gradClipNorm)
    
    // Environment settings
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    var maxStepsPerEpisode: Int = 500
    
    // Early stopping
    var earlyStopEnabled: Bool = TrainingDefaults.earlyStopEnabled
    var earlyStopWindow: Int = TrainingDefaults.earlyStopWindow
    var earlyStopRewardThreshold: Double = -100
    
    // Reward clipping
    var clipReward: Bool = TrainingDefaults.clipReward
    var clipRewardMin: Double = TrainingDefaults.clipRewardMin
    var clipRewardMax: Double = TrainingDefaults.clipRewardMax
    
    private var episodesCompletedInRun: Int = 0
    private var env: (any Env<MLXArray, Int>)?
    private var rngKey: MLXArray
    private var agent: AcrobotDQN?
    private var totalSteps: Int = 0
    
    var isWarmingUp: Bool = false
    var warmupProgress: Double {
        guard warmupSteps > 0 else { return 1.0 }
        return min(1.0, Double(totalSteps) / Double(warmupSteps))
    }
    
    var successRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let successes = recentEpisodes.filter { $0.success }.count
        return Double(successes) / Double(recentEpisodes.count)
    }
    
    
    init() {
        self.rngKey = MLX.key(0)
        setupEnvironment()
    }
    
    
    func setupEnvironment() {
        let renderMode: String? = renderEnabled ? "human" : nil
        var env = Gymnazo.make(
            "Acrobot",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: ["render_mode": renderMode as Any]
        ) as! any Env<MLXArray, Int>
        
        let _ = env.reset()
        self.env = env
        
        if let acrobot = env.unwrapped as? Acrobot {
            self.snapshot = renderEnabled ? acrobot.currentSnapshot : nil
        } else {
            self.snapshot = nil
        }
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(0)
        }
        
        self.agent = AcrobotDQN(
                learningRate: Float(learningRate),
                gamma: Float(gamma),
            epsilonStart: Float(epsilon),
                epsilonEnd: Float(epsilonMin),
                epsilonDecaySteps: epsilonDecaySteps,
                targetUpdateFrequency: targetUpdateFrequency,
                batchSize: batchSize,
            bufferCapacity: 10_000,
                gradClipNorm: Float(gradClipNorm)
            )
        
        episodeMetrics.removeAll()
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
        
        epsilon = Double(AcrobotDQN.Defaults.epsilonStart)
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = 0
        trainingCompletedNormally = false
        
        setupEnvironment()
    }
    
    func resetToDefaults() {
        learningRate = Double(AcrobotDQN.Defaults.learningRate)
        gamma = Double(AcrobotDQN.Defaults.gamma)
        epsilon = Double(AcrobotDQN.Defaults.epsilonStart)
        epsilonDecaySteps = AcrobotDQN.Defaults.epsilonDecaySteps
        epsilonMin = Double(AcrobotDQN.Defaults.epsilonEnd)
        batchSize = AcrobotDQN.Defaults.batchSize
        targetUpdateFrequency = AcrobotDQN.Defaults.targetUpdateFrequency
        gradClipNorm = Double(AcrobotDQN.Defaults.gradClipNorm)
        
        warmupSteps = TrainingDefaults.warmupSteps
        renderEnabled = TrainingDefaults.renderEnabled
        episodesPerRun = TrainingDefaults.episodesPerRun
        episodesCompletedInRun = 0
        useSeed = TrainingDefaults.useSeed
        seed = TrainingDefaults.seed
        maxStepsPerEpisode = 500
        earlyStopEnabled = TrainingDefaults.earlyStopEnabled
        earlyStopWindow = TrainingDefaults.earlyStopWindow
        earlyStopRewardThreshold = -100
        clipReward = TrainingDefaults.clipReward
        clipRewardMin = TrainingDefaults.clipRewardMin
        clipRewardMax = TrainingDefaults.clipRewardMax
        targetFPS = TrainingDefaults.targetFPS
        turboMode = TrainingDefaults.turboMode
    }
    
    
    func saveAgent(name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        let saved = try AgentStorage.shared.saveAcrobotAgent(
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
                "maxStepsPerEpisode": "\(maxStepsPerEpisode)"
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
        
        try AgentStorage.shared.updateAcrobotAgent(
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
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .acrobot else {
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
        
        setupEnvironment()
        
        let weightsDict = try AgentStorage.shared.loadNetworkWeights(for: savedAgent)
        
        guard let agent = self.agent else {
            throw AgentStorageError.dataCorrupted
        }
        
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        let newParams = NestedDictionary<String, MLXArray>.unflattened(weightsTuples)
        agent.policyNetwork.update(parameters: newParams)
        agent.targetNetwork.update(parameters: newParams)
        eval(agent.policyNetwork)
        eval(agent.targetNetwork)
        
        if let explorationSteps = savedAgent.hyperparameters["explorationSteps"] {
            agent.setExplorationSteps(Int(explorationSteps))
        }
        if let trainingSteps = savedAgent.hyperparameters["trainingSteps"] {
            agent.setSteps(Int(trainingSteps))
        }
        
        episodeMetrics = []
        episodeCount = savedAgent.episodesTrained + 1
        episodesCompletedInRun = 0
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
    }
    
    
    private func getCurrentSnapshot(from environment: any Env<MLXArray, Int>) -> AcrobotSnapshot {
        if let acrobot = environment as? Acrobot {
            return acrobot.currentSnapshot
        }
        
        if let wrapper = environment as? RecordEpisodeStatistics<TimeLimit<OrderEnforcing<PassiveEnvChecker<Acrobot>>>> {
            return wrapper.env.env.env.env.currentSnapshot
        }
        
        if let acrobot = environment.unwrapped as? Acrobot {
            return acrobot.currentSnapshot
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
                let randomAction = Int32.random(in: 0..<Int32(actSpace.n))
                let stepResult = warmupEnv.step(Int(randomAction))
                
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
            var totalLoss = 0.0
            var totalMeanQ = 0.0
            var totalGradNorm = 0.0
            var totalTdError = 0.0
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
            
            let updatesPerEpisode = max(1, steps / 10)
            for i in 0..<updatesPerEpisode {
                if let (loss, meanQ, gradNorm, tdError) = agent.update() {
                    totalLoss += Double(loss)
                    totalMeanQ += Double(meanQ)
                    totalGradNorm += Double(gradNorm)
                    totalTdError += Double(tdError)
                    lossCount += 1
                }
                if i % 5 == 0 {
                    await Task.yield()
                }
            }
            
            let finalReward = episodeRewardLocal
            let finalSteps = steps
            let avgLoss = lossCount > 0 ? totalLoss / Double(lossCount) : nil
            let avgMaxQ = lossCount > 0 ? totalMeanQ / Double(lossCount) : 0.0
            let avgGradNorm = lossCount > 0 ? totalGradNorm / Double(lossCount) : nil
            let avgTdError = lossCount > 0 ? totalTdError / Double(lossCount) : nil
            
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
                
                let completedEpisodeNumber = self.loadedEpisodeCount + self.episodeMetrics.count + 1
                
                // success: terminated before max steps (reached target height)
                let success = terminated && finalSteps < self.maxStepsPerEpisode
                
                let metric = EpisodeMetrics(
                    episode: completedEpisodeNumber,
                    reward: finalReward,
                    steps: finalSteps,
                    success: success,
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


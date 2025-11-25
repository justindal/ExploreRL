//
//  CartPoleRunner.swift
//

import Foundation
import ExploreRLCore
import SwiftUI
import MLX
import MLXNN

@MainActor
@Observable class CartPoleRunner {
    var snapshot: CartPoleSnapshot?
    var episodeCount = 1
    var currentStep = 0
    var totalReward = 0.0
    var isTraining = false
    
    var loadedAgentId: UUID?
    var loadedAgentName: String?
    var hasTrainedSinceLoad = false
    
    private var loadedEpisodeCount: Int = 0
    private var loadedBestReward: Double = 0
    
    var canResume: Bool {
        return agent != nil && episodeCount > 1
    }
    
    var totalEpisodesTrained: Int {
        return loadedEpisodeCount + episodeMetrics.count
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? 0
        return max(loadedBestReward, newBest)
    }
    
    var targetFPS: Double = DQNDefaults.targetFPS
    var turboMode: Bool = DQNDefaults.turboMode
    
    var learningRate: Double = DQNDefaults.learningRate
    var gamma: Double = DQNDefaults.gamma
    var epsilon: Double = DQNDefaults.epsilon
    var epsilonDecaySteps: Int = DQNDefaults.epsilonDecaySteps
    var epsilonMin: Double = DQNDefaults.epsilonMin
    var batchSize: Int = DQNDefaults.batchSize
    var tau: Double = DQNDefaults.tau
    var warmupSteps: Int = DQNDefaults.warmupSteps
    
    var renderEnabled: Bool = DQNDefaults.renderEnabled
    var episodesPerRun: Int = DQNDefaults.episodesPerRun
    private var episodesCompletedInRun: Int = 0
    var runProgress: Double {
        guard episodesPerRun > 0 else { return 0 }
        return Double(episodesCompletedInRun) / Double(episodesPerRun)
    }
    
    var useSeed: Bool = DQNDefaults.useSeed
    var seed: Int = DQNDefaults.seed
    var maxStepsPerEpisode: Int = DQNDefaults.maxStepsPerEpisode
    
    var earlyStopEnabled: Bool = DQNDefaults.earlyStopEnabled
    var earlyStopWindow: Int = DQNDefaults.earlyStopWindow
    var earlyStopRewardThreshold: Double = DQNDefaults.earlyStopRewardThreshold
    
    var clipReward: Bool = DQNDefaults.clipReward
    var clipRewardMin: Double = DQNDefaults.clipRewardMin
    var clipRewardMax: Double = DQNDefaults.clipRewardMax
    var gradClipNorm: Double = DQNDefaults.gradClipNorm
    
    var episodeMetrics: [EpisodeMetrics] = []
    var movingAverageWindow = 50
    
    private var env: (any Env<MLXArray, Int>)?
    
    /// Return the current snapshot from the environment for rendering.
    private func getCurrentSnapshot(from environment: any Env<MLXArray, Int>) -> CartPoleSnapshot {
        if let cp = environment as? CartPole {
            return cp.currentSnapshot
        }
        
        if let wrapper = environment as? RecordEpisodeStatistics<TimeLimit<OrderEnforcing<PassiveEnvChecker<CartPole>>>> {
            return wrapper.env.env.env.env.currentSnapshot
        }
        
        // fallback
        if let cp = environment.unwrapped as? CartPole {
            return cp.currentSnapshot
        }
        
        return .zero
    }
    
    private var rngKey: MLXArray
    private var agent: DQNAgent?
    private var totalSteps: Int = 0
    
    var successRate: Double {
        // threshold for success, might change
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let successes = recentEpisodes.filter { $0.steps >= 200 }.count
        return Double(successes) / Double(recentEpisodes.count)
    }
    
    var averageReward: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { $0.reward }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    init() {
        self.rngKey = MLX.key(0)
        setupEnvironment()
    }
    
    func setupEnvironment() {
        Gymnasium.start()
        
        var env = Gymnasium.make(
            "CartPole-v1",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: ["render_mode": renderEnabled ? "human" : nil]
        ) as! any Env<MLXArray, Int>
        
        let _ = env.reset()
        self.env = env
        
        if let cartPole = env.unwrapped as? CartPole {
            self.snapshot = renderEnabled ? cartPole.currentSnapshot : nil
        } else {
            self.snapshot = nil
        }
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(0)
        }
        
        if let obsSpace = env.observation_space as? Box,
           let actSpace = env.action_space as? Discrete {
            self.agent = DQNAgent(
                observationSpace: obsSpace,
                actionSpace: actSpace,
                hiddenDimensions: 128,
                learningRate: Float(learningRate),
                gamma: Float(gamma),
                epsilon: Float(epsilon),
                epsilonEnd: Float(epsilonMin),
                epsilonDecaySteps: epsilonDecaySteps,
                tau: Float(tau),
                batchSize: batchSize,
                bufferSize: 10_000,
                gradClipNorm: Float(gradClipNorm)
            )
        } else {
            self.agent = nil
        }
        
        episodeMetrics.removeAll()
        totalReward = 0
        episodeCount = 1
        currentStep = 0
        totalSteps = 0
        episodesCompletedInRun = 0
    }
    
    func startTraining() {
        guard !isTraining else { return }
        isTraining = true
        hasTrainedSinceLoad = true
        TrainingState.shared.startTraining(environment: "Cart Pole")
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            await self.runTrainingLoop()
        }
    }
    
    func stopTraining() {
        isTraining = false
        TrainingState.shared.stopTraining()
    }
    
    func reset() {
        stopTraining()
        
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = 0
        
        Task {
            setupEnvironment()
        }
    }
    
    func resetToDefaults() {
        learningRate = DQNDefaults.learningRate
        gamma = DQNDefaults.gamma
        epsilon = DQNDefaults.epsilon
        epsilonDecaySteps = DQNDefaults.epsilonDecaySteps
        epsilonMin = DQNDefaults.epsilonMin
        batchSize = DQNDefaults.batchSize
        tau = DQNDefaults.tau
        warmupSteps = DQNDefaults.warmupSteps
        renderEnabled = DQNDefaults.renderEnabled
        episodesPerRun = DQNDefaults.episodesPerRun
        episodesCompletedInRun = 0
        useSeed = DQNDefaults.useSeed
        seed = DQNDefaults.seed
        maxStepsPerEpisode = DQNDefaults.maxStepsPerEpisode
        earlyStopEnabled = DQNDefaults.earlyStopEnabled
        earlyStopWindow = DQNDefaults.earlyStopWindow
        earlyStopRewardThreshold = DQNDefaults.earlyStopRewardThreshold
        clipReward = DQNDefaults.clipReward
        clipRewardMin = DQNDefaults.clipRewardMin
        clipRewardMax = DQNDefaults.clipRewardMax
        gradClipNorm = DQNDefaults.gradClipNorm
        targetFPS = DQNDefaults.targetFPS
        turboMode = DQNDefaults.turboMode
    }
    
    func saveAgent(name: String) throws -> SavedAgent {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        let saved = try AgentStorage.shared.saveCartPoleAgent(
            name: name,
            policyNetwork: agent.policyNetwork,
            episodesTrained: totalEpisodesTrained,
            epsilon: epsilon,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "learningRate": learningRate,
                "gamma": gamma,
                "epsilon": epsilon,
                "epsilonMin": epsilonMin,
                "epsilonDecaySteps": Double(epsilonDecaySteps),
                "tau": tau,
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
        
        return saved
    }
    
    func updateAgent(id: UUID, name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        try AgentStorage.shared.updateCartPoleAgent(
            id: id,
            newName: name,
            policyNetwork: agent.policyNetwork,
            episodesTrained: totalEpisodesTrained,
            epsilon: epsilon,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "learningRate": learningRate,
                "gamma": gamma,
                "epsilon": epsilon,
                "epsilonMin": epsilonMin,
                "epsilonDecaySteps": Double(epsilonDecaySteps),
                "tau": tau,
                "batchSize": Double(batchSize),
                "gradClipNorm": gradClipNorm,
                "warmupSteps": Double(warmupSteps),
                "explorationSteps": Double(agent.currentExplorationSteps),
                "trainingSteps": Double(agent.currentSteps)
            ]
        )
        
        loadedAgentName = name
        hasTrainedSinceLoad = false
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .cartPole else {
            throw AgentStorageError.wrongEnvironmentType
        }
        
        stopTraining()
        
        if let lr = savedAgent.hyperparameters["learningRate"] {
            learningRate = lr
        }
        if let g = savedAgent.hyperparameters["gamma"] {
            gamma = g
        }
        if let eps = savedAgent.hyperparameters["epsilon"] {
            epsilon = eps
        }
        if let epsMin = savedAgent.hyperparameters["epsilonMin"] {
            epsilonMin = epsMin
        }
        if let decaySteps = savedAgent.hyperparameters["epsilonDecaySteps"] {
            epsilonDecaySteps = Int(decaySteps)
        }
        if let t = savedAgent.hyperparameters["tau"] {
            tau = t
        }
        if let bs = savedAgent.hyperparameters["batchSize"] {
            batchSize = Int(bs)
        }
        if let gcn = savedAgent.hyperparameters["gradClipNorm"] {
            gradClipNorm = gcn
        }
        if let wSteps = savedAgent.hyperparameters["warmupSteps"] {
            warmupSteps = Int(wSteps)
        }
        
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
        guard let newParams = try? NestedDictionary<String, MLXArray>.unflattened(weightsTuples) else {
            throw AgentStorageError.dataCorrupted
        }
        agent.policyNetwork.update(parameters: newParams)
        agent.targetNetwork.update(parameters: newParams)
        eval(agent.policyNetwork)
        eval(agent.targetNetwork)
        
        print("Loaded agent weights successfully. Keys: \(weightsDict.keys.sorted())")
        
        if let explorationSteps = savedAgent.hyperparameters["explorationSteps"] {
            agent.setExplorationSteps(Int(explorationSteps))
            print("Restored exploration steps: \(Int(explorationSteps))")
        }
        if let trainingSteps = savedAgent.hyperparameters["trainingSteps"] {
            agent.setSteps(Int(trainingSteps))
        }
        
        episodeMetrics = []
        episodeCount = savedAgent.episodesTrained
        episodesCompletedInRun = 0
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
    }
    
    private func runTrainingLoop() async {
        while isTraining {
            guard var env = self.env, let agent = self.agent else { break }
            
            let resetResult = env.reset()
            self.env = env
            var state = resetResult.obs
            
            var terminated = false
            var truncated = false
            var steps = 0
            var episodeReward = 0.0
            var totalLoss = 0.0
            var totalMeanQ = 0.0
            var totalGradNorm = 0.0
            var totalTdError = 0.0
            var lossCount = 0
            
            if !turboMode || episodeCount % 10 == 0 {
                await MainActor.run {
                    self.currentStep = 0
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
                episodeReward += usedReward
                
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
                    let updateResult = agent.update()
                    if let (loss, meanQ, gradNorm, tdError) = updateResult {
                        totalLoss += Double(loss)
                        totalMeanQ += Double(meanQ)
                        totalGradNorm += Double(gradNorm)
                        totalTdError += Double(tdError)
                        lossCount += 1
                    }
                }
                
                state = nextState
                
                if !turboMode {
                    let currentS = steps
                    if renderEnabled {
                        let snap = getCurrentSnapshot(from: env)
                        await MainActor.run {
                            self.snapshot = snap
                            self.currentStep = currentS
                        }
                        let delayNs = UInt64(1_000_000_000 / self.targetFPS)
                        try? await Task.sleep(nanoseconds: delayNs)
                    } else {
                        Task { @MainActor in
                            self.currentStep = currentS
                        }
                    }
                }
            }
            
            let finalReward = episodeReward
            let finalSteps = steps
            let avgLoss = lossCount > 0 ? totalLoss / Double(lossCount) : nil
            let avgMaxQ = lossCount > 0 ? totalMeanQ / Double(lossCount) : 0.0
            let avgGradNorm = lossCount > 0 ? totalGradNorm / Double(lossCount) : nil
            let avgTdError = lossCount > 0 ? totalTdError / Double(lossCount) : nil
            
            if episodeCount % 50 == 0 {
                GPU.clearCache()
            }
            
            await MainActor.run {
                self.episodeCount += 1
                self.totalReward += finalReward
                self.episodesCompletedInRun += 1
                if let agent = self.agent {
                    self.epsilon = Double(agent.epsilon)
                }
                
                let window = max(1, min(self.movingAverageWindow, self.episodeMetrics.count + 1))
                let recentRewards = self.episodeMetrics.suffix(window - 1).map { $0.reward }
                let rewardSum = recentRewards.reduce(0, +) + finalReward
                let rewardMovingAverage = rewardSum / Double(window)
                
                let metric = EpisodeMetrics(
                    episode: self.episodeCount,
                    reward: finalReward,
                    steps: finalSteps,
                    success: finalSteps >= 200,
                    averageTDError: avgTdError ?? 0,
                    averageLoss: avgLoss,
                    averageMaxQ: avgMaxQ,
                    epsilon: self.epsilon,
                    averageGradNorm: avgGradNorm,
                    rewardMovingAverage: rewardMovingAverage
                )
                self.episodeMetrics.append(metric)
            }
            
            if earlyStopEnabled {
                let window = max(1, earlyStopWindow)
                let recent = self.episodeMetrics.suffix(window)
                if !recent.isEmpty {
                    let avg = recent.map { $0.reward }.reduce(0, +) / Double(recent.count)
                    if avg >= earlyStopRewardThreshold {
                        await MainActor.run { self.isTraining = false }
                        break
                    }
                }
            }
            
            if episodesPerRun > 0 && episodesCompletedInRun >= episodesPerRun {
                await MainActor.run {
                    self.isTraining = false
                }
                break
            }
            
            if turboMode {
                await Task.yield()
            }
        }
        
        await MainActor.run {
            self.isTraining = false
        }
    }
}

//
//  FrozenLakeRunner.swift
//

import SwiftUI
import ExploreRLCore
import MLX
import MLXRandom

@MainActor
@Observable class FrozenLakeRunner {
    // current env
    var snapshot: FrozenLakeRenderSnapshot?
    var currentPolicy: [Int]?
    var episodeCount = 1
    var currentStep = 0
    var totalReward = 0.0
    var isTraining = false
    
    var currentMap: [String] = []
    
    var targetFPS: Double = 60.0
    var turboMode: Bool = false
    var mapName: String = "4x4"
    var customMapSize: Int = 8
    var isSlippery: Bool = false
    var showPolicy: Bool = false {
        didSet {
            updateSnapshot()
        }
    }
    
    // hyperparameters and settings
    var learningRate: Float = 0.8
    var gamma: Float = 0.95
    var epsilon: Float = 1.0
    var minEpsilon: Float = 0.01
    var epsilonDecay: Float = 0.995
    var episodesPerRun: Int = 2000
    var maxStepsPerEpisode: Int = 100
    
    var episodeMetrics: [EpisodeMetrics] = []
    var movingAverageWindow = 100
    
    private var env: (any Env<Int, Int>)?
    private var agent: QLearningAgent?
    private var rngKey: MLXArray
    
    var successRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let successes = recentEpisodes.filter { $0.success }.count
        return Double(successes) / Double(recentEpisodes.count)
    }
    
    var averageReward: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { $0.reward }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    var averageSteps: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { Double($0.steps) }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    var averageTDError: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { $0.averageTDError }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    var averageMaxQ: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { $0.averageMaxQ }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    init() {
        self.rngKey = MLXRandom.key(0)
        setupEnvironment()
    }
    
    func setupEnvironment() {
        Gymnasium.start()
        
        var kwargs: [String: Any] = [
            "render_mode": "rgb_array",
            "is_slippery": isSlippery,
            "map_name": mapName
        ]
        
        var desc: [String]
        if mapName == "Custom" {
            desc = FrozenLake.generateRandomMap(size: customMapSize)
        } else {
            desc = FrozenLake.MAPS[mapName] ?? FrozenLake.MAPS["4x4"]!
        }
        
        kwargs["desc"] = desc
        self.currentMap = desc
        
        self.rngKey = MLXRandom.key(0)
        
        guard let madeEnv = Gymnasium.make(
            "FrozenLake-v1",
            kwargs: kwargs
        ) as? any Env<Int, Int> else {
            print("Failed to create FrozenLake environment")
            return
        }
        
        self.env = madeEnv
        
        guard let obsSpace = madeEnv.observation_space as? Discrete,
              let actSpace = madeEnv.action_space as? Discrete else {
            print("FrozenLake spaces mismatch")
            return
        }
        
        self.agent = QLearningAgent(
            learningRate: learningRate,
            gamma: gamma,
            stateSize: obsSpace.n,
            actionSize: actSpace.n,
            epsilon: epsilon
        )
        
        _ = self.env?.reset(seed: 42)
        updateSnapshot()
        
        episodeMetrics.removeAll()
        totalReward = 0
        episodeCount = 1
        currentStep = 0
    }
    
    private func updateSnapshot() {
        if let frozenLake = self.env?.unwrapped as? FrozenLake {
            self.snapshot = frozenLake.currentSnapshot
            if showPolicy, let agent = agent {
                let qTable = agent.qTable
                let policyArray = MLX.argMax(qTable, axis: 1).asArray(Int32.self)
                self.currentPolicy = policyArray.map { Int($0) }
            } else {
                self.currentPolicy = nil
            }
        }
    }
    
    func startTraining() {
        guard !isTraining else { return }
        isTraining = true
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            // TODO use Sendable in future
            
            await self.runTrainingLoop()
        }
    }
    
    func stopTraining() {
        isTraining = false
    }
    
    func reset() {
        stopTraining()
        Task {
            setupEnvironment()
        }
    }
    
    private func runTrainingLoop() async {
        let targetEpisodes = episodeCount + episodesPerRun
        
        for episode in episodeCount..<targetEpisodes {
            if !isTraining { break }
            
            guard var env = self.env, var agent = self.agent else { break }
            
            let resetResult = env.reset()
            var currentState = resetResult.obs
            
            var terminated = false
            var truncated = false
            var steps = 0
            var episodeReward = 0.0
            var totalTDError = 0.0
            
            if !turboMode || episode % 10 == 0 {
                self.episodeCount = episode + 1
                self.currentStep = 0
            }
            
            while !terminated && !truncated {
                if !isTraining { break }
                
                if steps >= maxStepsPerEpisode {
                    truncated = true
                    break
                }
                
                guard let actionSpace = env.action_space as? Discrete else { break }
                var key = self.rngKey
                let action = agent.chooseAction(
                    actionSpace: actionSpace,
                    state: currentState,
                    key: &key
                )
                self.rngKey = key
                
                let result = env.step(action)
                let nextState = result.obs
                let reward = Float(result.reward)
                
                let updateResult = agent.update(
                    state: currentState,
                    action: action,
                    reward: reward,
                    nextState: nextState
                )
                
                totalTDError += Double(abs(updateResult.tdError))
                
                currentState = nextState
                terminated = result.terminated
                truncated = result.truncated
                steps += 1
                episodeReward += result.reward
                
                self.agent = agent
                
                let shouldUpdateUI = !turboMode || (terminated || truncated)
                
                if shouldUpdateUI {
                    if let frozenLake = env.unwrapped as? FrozenLake {
                        self.snapshot = frozenLake.currentSnapshot
                        
                        if self.showPolicy {
                            let qTable = agent.qTable
                            let policyArray = MLX.argMax(qTable, axis: 1).asArray(Int32.self)
                            self.currentPolicy = policyArray.map { Int($0) }
                        } else {
                            self.currentPolicy = nil
                        }
                        
                        self.currentStep = steps
                    }
                    
                    if !turboMode {
                        let delayNs = UInt64(1_000_000_000 / self.targetFPS)
                        try? await Task.sleep(nanoseconds: delayNs)
                    }
                }
            }
            
            let avgTDError = totalTDError / Double(max(1, steps))
            
            let qTable = agent.qTable
            let maxQPerState = qTable.max(axis: 1)
            let avgMaxQ = (maxQPerState.mean().item() as Float)
            
            let success = episodeReward > 0
            let metric = EpisodeMetrics(
                episode: episode + 1,
                reward: episodeReward,
                steps: steps,
                success: success,
                averageTDError: avgTDError,
                averageMaxQ: Double(avgMaxQ),
                epsilon: Double(epsilon)
            )
            
            self.episodeMetrics.append(metric)
            if success {
                self.totalReward += episodeReward
            }
            
            if epsilon > minEpsilon {
                epsilon = max(minEpsilon, epsilon * epsilonDecay)
                if var agent = self.agent {
                    agent.epsilon = epsilon
                    self.agent = agent
                }
            }
            
            if turboMode {
                await Task.yield()
            }
        }
        
        self.isTraining = false
    }
    
    func calculateMovingAverage(for metric: EpisodeMetrics, getValue: (EpisodeMetrics) -> Double) -> Double {
        let episodeIndex = metric.episode
        let startIdx = max(0, episodeIndex - movingAverageWindow + 1)
        let endIdx = episodeIndex
        
        guard startIdx < episodeMetrics.count, endIdx < episodeMetrics.count else { return 0.0 }
        
        let window = episodeMetrics[startIdx...endIdx]
        guard !window.isEmpty else { return 0.0 }
        
        let sum = window.map(getValue).reduce(0, +)
        return sum / Double(window.count)
    }
}

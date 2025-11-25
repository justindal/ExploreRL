//
//  EvaluationRunner.swift
//

import Foundation
import SwiftUI
import ExploreRLCore
import MLX
import MLXNN

@MainActor
@Observable class EvaluationRunner {
    var isRunning = false
    var currentEpisode = 0
    var currentStep = 0
    var episodeReward = 0.0
    var totalReward = 0.0
    var successCount = 0
    
    var episodesToRun = 100
    var targetFPS: Double = 30.0
    var showVisualization = true
    
    var episodeRewards: [Double] = []
    var episodeSteps: [Int] = []
    
    private(set) var loadedAgent: SavedAgent?
    
    var frozenLakeSnapshot: FrozenLakeRenderSnapshot?
    var frozenLakePolicy: [Int]?
    var frozenLakeMap: [String] = []
    private var frozenLakeEnv: (any Env<Int, Int>)?
    private var frozenLakeAgent: DiscreteAgent?
    
    var cartPoleSnapshot: CartPoleSnapshot?
    private var cartPoleEnv: (any Env<MLXArray, Int>)?
    private var cartPoleAgent: DQNAgent?
    
    private var rngKey: MLXArray = MLX.key(0)
    
    var averageReward: Double {
        guard !episodeRewards.isEmpty else { return 0 }
        return episodeRewards.reduce(0, +) / Double(episodeRewards.count)
    }
    
    var successRate: Double {
        guard currentEpisode > 0 else { return 0 }
        return Double(successCount) / Double(currentEpisode)
    }
    
    var averageSteps: Double {
        guard !episodeSteps.isEmpty else { return 0 }
        return Double(episodeSteps.reduce(0, +)) / Double(episodeSteps.count)
    }
    
    func loadAgent(_ agent: SavedAgent) throws {
        loadedAgent = agent
        episodeRewards = []
        episodeSteps = []
        currentEpisode = 0
        totalReward = 0
        successCount = 0
        
        switch agent.environmentType {
        case .frozenLake:
            try setupFrozenLake(agent)
        case .cartPole:
            try setupCartPole(agent)
        }
    }
    
    private func setupFrozenLake(_ agent: SavedAgent) throws {
        Gymnasium.start()
        
        let mapName = agent.environmentConfig["mapName"] ?? "4x4"
        let isSlippery = agent.environmentConfig["isSlippery"] == "true"
        
        var kwargs: [String: Any] = [
            "render_mode": "rgb_array",
            "is_slippery": isSlippery,
            "map_name": mapName
        ]
        
        let desc: [String]
        if mapName == "Custom", let sizeStr = agent.environmentConfig["mapSize"],
           let size = Int(sizeStr) {
            desc = FrozenLake.generateRandomMap(size: size)
        } else {
            desc = FrozenLake.MAPS[mapName] ?? FrozenLake.MAPS["4x4"]!
        }
        kwargs["desc"] = desc
        frozenLakeMap = desc
        
        guard let env = Gymnasium.make("FrozenLake-v1", kwargs: kwargs) as? any Env<Int, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        frozenLakeEnv = env
        
        let qTable = try AgentStorage.shared.loadQTable(for: agent)
        
        guard let obsSpace = env.observation_space as? Discrete,
              let actSpace = env.action_space as? Discrete else {
            throw AgentStorageError.dataCorrupted
        }
        
        let qAgent = QLearningAgent(
            learningRate: 0,
            gamma: 0.95,
            stateSize: obsSpace.n,
            actionSize: actSpace.n,
            epsilon: 0
        )
        
        qAgent.loadQTable(qTable)
        
        frozenLakeAgent = DiscreteAgent(qAgent)
        
        if let fl = env.unwrapped as? FrozenLake {
            frozenLakeSnapshot = fl.currentSnapshot
            
            let policyArray = MLX.argMax(qTable, axis: 1).asArray(Int32.self)
            frozenLakePolicy = policyArray.map { Int($0) }
        }
    }
    
    private func setupCartPole(_ agent: SavedAgent) throws {
        Gymnasium.start()
        
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "500") ?? 500
        
        guard var env = Gymnasium.make(
            "CartPole-v1",
            maxEpisodeSteps: maxSteps,
            kwargs: ["render_mode": showVisualization ? "human" : nil]
        ) as? any Env<MLXArray, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        cartPoleEnv = env
        
        guard let obsSpace = env.observation_space as? Box,
              let actSpace = env.action_space as? Discrete else {
            throw AgentStorageError.dataCorrupted
        }
        
        let dqnAgent = DQNAgent(
            observationSpace: obsSpace,
            actionSpace: actSpace,
            hiddenDimensions: 128,
            learningRate: 0,
            gamma: 0.99,
            epsilon: 0,
            epsilonEnd: 0,
            epsilonDecaySteps: 1,
            tau: 0,
            batchSize: 64,
            bufferSize: 1000,
            gradClipNorm: 100
        )
        
        let weightsDict = try AgentStorage.shared.loadNetworkWeights(for: agent)
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        if let newParams = try? NestedDictionary<String, MLXArray>.unflattened(weightsTuples) {
            dqnAgent.policyNetwork.update(parameters: newParams)
            eval(dqnAgent.policyNetwork)
        }
        
        cartPoleAgent = dqnAgent
        
        if let cp = env.unwrapped as? CartPole {
            cartPoleSnapshot = cp.currentSnapshot
        }
    }
    
    func startEvaluation() {
        guard !isRunning, loadedAgent != nil else { return }
        isRunning = true
        episodeRewards = []
        episodeSteps = []
        currentEpisode = 0
        totalReward = 0
        successCount = 0
        
        Task.detached { [weak self] in
            await self?.runEvaluationLoop()
        }
    }
    
    func stopEvaluation() {
        isRunning = false
    }
    
    private func runEvaluationLoop() async {
        guard let agent = loadedAgent else { return }
        
        for episode in 0..<episodesToRun {
            if !isRunning { break }
            
            currentEpisode = episode + 1
            currentStep = 0
            episodeReward = 0
            
            switch agent.environmentType {
            case .frozenLake:
                await runFrozenLakeEpisode()
            case .cartPole:
                await runCartPoleEpisode()
            }
        }
        
        isRunning = false
    }
    
    private func runFrozenLakeEpisode() async {
        guard var env = frozenLakeEnv, let agent = frozenLakeAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        guard let actionSpace = env.action_space as? Discrete else { return }
        
        while !terminated && !truncated && isRunning {
            var key = rngKey
            let action = agent.chooseAction(actionSpace: actionSpace, state: state, key: &key)
            rngKey = key
            
            let result = env.step(action)
            state = result.obs
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            currentStep = steps
            episodeReward = reward
            
            if showVisualization {
                if let fl = env.unwrapped as? FrozenLake {
                    frozenLakeSnapshot = fl.currentSnapshot
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        frozenLakeEnv = env
        episodeRewards.append(reward)
        episodeSteps.append(steps)
        totalReward += reward
        
        if reward > 0 {
            successCount += 1
        }
    }
    
    private func runCartPoleEpisode() async {
        guard var env = cartPoleEnv, let agent = cartPoleAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        guard let actionSpace = env.action_space as? Discrete else { return }
        
        while !terminated && !truncated && isRunning {
            var key = rngKey
            let actionArray = agent.chooseAction(state: state, actionSpace: actionSpace, key: &key)
            rngKey = key
            let action = actionArray.item(Int.self)
            
            let result = env.step(action)
            state = result.obs
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            currentStep = steps
            episodeReward = reward
            
            if showVisualization {
                if let cp = env.unwrapped as? CartPole {
                    cartPoleSnapshot = cp.currentSnapshot
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        cartPoleEnv = env
        episodeRewards.append(reward)
        episodeSteps.append(steps)
        totalReward += reward
        
        if steps >= 200 {
            successCount += 1
        }
    }
}


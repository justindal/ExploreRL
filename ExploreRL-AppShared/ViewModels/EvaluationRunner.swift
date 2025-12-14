//
//  EvaluationRunner.swift
//

import Foundation
import SwiftUI
import Gymnazo
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
    
    // FrozenLake
    var frozenLakeSnapshot: FrozenLakeRenderSnapshot?
    var frozenLakePolicy: [Int]?
    var frozenLakeMap: [String] = []
    private var frozenLakeEnv: (any Env<Int, Int>)?
    private var frozenLakeAgent: DiscreteAgent?
    
    // CartPole
    var cartPoleSnapshot: CartPoleSnapshot?
    private var cartPoleEnv: (any Env<MLXArray, Int>)?
    private var cartPoleAgent: CartPoleDQN?
    
    // MountainCar
    var mountainCarSnapshot: MountainCarSnapshot?
    private var mountainCarEnv: (any Env<MLXArray, Int>)?
    private var mountainCarAgent: MountainCarDQN?
    
    // MountainCarContinuous
    var mountainCarContinuousSnapshot: MountainCarSnapshot?
    private var mountainCarContinuousEnv: (any Env<MLXArray, MLXArray>)?
    private var mountainCarContinuousAgent: MountainCarContinuousSAC?
    
    // Acrobot
    var acrobotSnapshot: AcrobotSnapshot?
    private var acrobotEnv: (any Env<MLXArray, Int>)?
    private var acrobotAgent: AcrobotDQN?
    
    // Pendulum
    var pendulumSnapshot: PendulumSnapshot?
    private var pendulumEnv: (any Env<MLXArray, MLXArray>)?
    private var pendulumAgent: PendulumSAC?
    
    // LunarLander
    var lunarLanderSnapshot: LunarLanderSnapshot?
    private var lunarLanderEnv: (any Env<MLXArray, Int>)?
    private var lunarLanderAgent: LunarLanderDQN?
    
    // LunarLanderContinuous
    var lunarLanderContinuousSnapshot: LunarLanderSnapshot?
    private var lunarLanderContinuousEnv: (any Env<MLXArray, MLXArray>)?
    private var lunarLanderContinuousAgent: LunarLanderContinuousSAC?
    
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
        case .mountainCar:
            try setupMountainCar(agent)
        case .mountainCarContinuous:
            try setupMountainCarContinuous(agent)
        case .acrobot:
            try setupAcrobot(agent)
        case .pendulum:
            try setupPendulum(agent)
        case .lunarLander:
            try setupLunarLander(agent)
        case .lunarLanderContinuous:
            try setupLunarLanderContinuous(agent)
        }
    }
    
    private func setupFrozenLake(_ agent: SavedAgent) throws {
        let mapName = agent.environmentConfig["mapName"] ?? "4x4"
        let isSlippery = agent.environmentConfig["isSlippery"] == "true"
        
        var kwargs: [String: Any] = [
            "render_mode": "rgb_array",
            "is_slippery": isSlippery,
            "map_name": mapName
        ]
        
        let desc: [String]
        if let mapDataString = agent.environmentConfig["mapData"],
           let mapData = mapDataString.data(using: .utf8),
           let decodedMap = try? JSONDecoder().decode([String].self, from: mapData),
           !decodedMap.isEmpty {
            desc = decodedMap
        } else if mapName == "Custom", let sizeStr = agent.environmentConfig["mapSize"],
           let size = Int(sizeStr) {
            desc = FrozenLake.generateRandomMap(size: size)
        } else {
            desc = FrozenLake.MAPS[mapName] ?? FrozenLake.MAPS["4x4"]!
        }
        kwargs["desc"] = desc
        frozenLakeMap = desc
        
        guard let env = Gymnazo.make("FrozenLake-v1", kwargs: kwargs) as? any Env<Int, Int> else {
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
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "500") ?? 500
        
        let renderMode: String? = showVisualization ? "human" : nil
        guard var env = Gymnazo.make(
            "CartPole-v1",
            maxEpisodeSteps: maxSteps,
            kwargs: ["render_mode": renderMode as Any]
        ) as? any Env<MLXArray, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        cartPoleEnv = env
        
        let dqnAgent = CartPoleDQN(
            learningRate: 0,
            gamma: 0.99,
            epsilonStart: 0,
            epsilonEnd: 0,
            epsilonDecaySteps: 1,
            targetUpdateFrequency: 1,
            batchSize: 64,
            bufferCapacity: 1000,
            gradClipNorm: 100
        )
        
        let weightsDict = try AgentStorage.shared.loadNetworkWeights(for: agent)
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        let newParams = NestedDictionary<String, MLXArray>.unflattened(weightsTuples)
        dqnAgent.policyNetwork.update(parameters: newParams)
        eval(dqnAgent.policyNetwork)
        
        cartPoleAgent = dqnAgent
        
        if let cp = env.unwrapped as? CartPole {
            cartPoleSnapshot = cp.currentSnapshot
        }
    }
    
    private func setupMountainCar(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        
        var kwargs: [String: Any] = [:]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "MountainCar-v0",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? any Env<MLXArray, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        mountainCarEnv = env
        
        let dqnAgent = MountainCarDQN(
            learningRate: 0,
            gamma: 0.99,
            epsilonStart: 0,
            epsilonEnd: 0,
            epsilonDecaySteps: 1,
            targetUpdateFrequency: 1,
            batchSize: 64,
            bufferCapacity: 1000,
            gradClipNorm: 100
        )
        
        let weightsDict = try AgentStorage.shared.loadNetworkWeights(for: agent)
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        let newParams = NestedDictionary<String, MLXArray>.unflattened(weightsTuples)
        dqnAgent.policyNetwork.update(parameters: newParams)
        eval(dqnAgent.policyNetwork)
        
        mountainCarAgent = dqnAgent
        
        if let mc = env.unwrapped as? MountainCar {
            mountainCarSnapshot = mc.currentSnapshot
        }
    }
    
    private func setupMountainCarContinuous(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "999") ?? 999
        
        var kwargs: [String: Any] = [:]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "MountainCarContinuous-v0",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        mountainCarContinuousEnv = env
        
        let sacAgent = MountainCarContinuousSAC(
            learningRate: 0,
            gamma: 0.99,
            tau: 0.005,
            alpha: Float(agent.finalEpsilon),
            batchSize: 256,
            bufferSize: 1000
        )
        
        if agent.algorithmType == "SAC-Vmap" || agent.agentDataPath.contains("vmap") {
            let weightsDict = try AgentStorage.shared.loadSACVmapWeights(for: agent)
            
            if let actorWeights = weightsDict["actor"] {
                let actorTuples = actorWeights.map { ($0.key, $0.value) }
                let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
                sacAgent.actor.update(parameters: actorParams)
            }
            
            if let qEnsembleWeights = weightsDict["qEnsemble"] {
                let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
                let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
                sacAgent.qEnsemble.update(parameters: qParams)
            }
        } else {
            let weightsDict = try AgentStorage.shared.loadSACWeights(for: agent)
            
            if let actorWeights = weightsDict["actor"] {
                let actorTuples = actorWeights.map { ($0.key, $0.value) }
                let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
                sacAgent.actor.update(parameters: actorParams)
            }
        }
        
        eval(sacAgent.actor, sacAgent.qEnsemble)
        
        mountainCarContinuousAgent = sacAgent
        
        if let mc = env.unwrapped as? MountainCarContinuous {
            mountainCarContinuousSnapshot = mc.currentSnapshot
        }
    }
    
    private func setupAcrobot(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "500") ?? 500
        
        let renderMode: String? = showVisualization ? "human" : nil
        guard var env = Gymnazo.make(
            "Acrobot-v1",
            maxEpisodeSteps: maxSteps,
            kwargs: ["render_mode": renderMode as Any]
        ) as? any Env<MLXArray, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        acrobotEnv = env
        
        let dqnAgent = AcrobotDQN(
            learningRate: 0,
            gamma: 0.99,
            epsilonStart: 0,
            epsilonEnd: 0,
            epsilonDecaySteps: 1,
            targetUpdateFrequency: 1,
            batchSize: 64,
            bufferCapacity: 1000,
            gradClipNorm: 100
        )
        
        let weightsDict = try AgentStorage.shared.loadNetworkWeights(for: agent)
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        let newParams = NestedDictionary<String, MLXArray>.unflattened(weightsTuples)
        dqnAgent.policyNetwork.update(parameters: newParams)
        eval(dqnAgent.policyNetwork)
        
        acrobotAgent = dqnAgent
        
        if let acrobot = env.unwrapped as? Acrobot {
            acrobotSnapshot = acrobot.currentSnapshot
        }
    }
    
    private func setupPendulum(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        
        var kwargs: [String: Any] = [:]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "Pendulum-v1",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        pendulumEnv = env
        
        let sacAgent = PendulumSAC(
            learningRate: 0,
            gamma: 0.99,
            tau: 0.005,
            alpha: Float(agent.finalEpsilon),
            batchSize: 256,
            bufferSize: 1000
        )
        
        let weightsDict = try AgentStorage.shared.loadPendulumWeights(for: agent)
        
        if let actorWeights = weightsDict["actor"] {
            let actorTuples = actorWeights.map { ($0.key, $0.value) }
            let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
            sacAgent.actor.update(parameters: actorParams)
        }
        
        if let qEnsembleWeights = weightsDict["qEnsemble"] {
            let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
            let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
            sacAgent.qEnsemble.update(parameters: qParams)
        }
        
        eval(sacAgent.actor, sacAgent.qEnsemble)
        
        pendulumAgent = sacAgent
        
        if let pendulum = env.unwrapped as? Pendulum {
            pendulumSnapshot = pendulum.currentSnapshot
        }
    }
    
    private func setupLunarLander(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        
        let kwargs: [String: Any] = showVisualization ? ["render_mode": "human"] : [:]
        
        guard var env = Gymnazo.make(
            "LunarLander-v3",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? any Env<MLXArray, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        lunarLanderEnv = env
        
        let dqnAgent = LunarLanderDQN(
            learningRate: 0,
            gamma: 0.99,
            epsilonStart: 0,
            epsilonEnd: 0,
            epsilonDecaySteps: 1,
            targetUpdateFrequency: 1,
            batchSize: 64,
            bufferCapacity: 1000,
            gradClipNorm: 100
        )
        
        let weightsDict = try AgentStorage.shared.loadLunarLanderWeights(for: agent)
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        let newParams = NestedDictionary<String, MLXArray>.unflattened(weightsTuples)
        dqnAgent.policyNetwork.update(parameters: newParams)
        eval(dqnAgent.policyNetwork)
        
        lunarLanderAgent = dqnAgent
        
        if let lander = env.unwrapped as? LunarLander {
            lunarLanderSnapshot = lander.currentSnapshot
        }
    }
    
    private func setupLunarLanderContinuous(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        
        var kwargs: [String: Any] = [:]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "LunarLanderContinuous-v3",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        lunarLanderContinuousEnv = env
        
        let sacAgent = LunarLanderContinuousSAC(
            learningRate: 0,
            gamma: 0.99,
            tau: 0.005,
            alpha: Float(agent.finalEpsilon),
            batchSize: 256,
            bufferSize: 1000
        )
        
        let weightsDict = try AgentStorage.shared.loadLunarLanderContinuousWeights(for: agent)
        
        if let actorWeights = weightsDict["actor"] {
            let actorTuples = actorWeights.map { ($0.key, $0.value) }
            let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
            sacAgent.actor.update(parameters: actorParams)
        }
        
        if let qEnsembleWeights = weightsDict["qEnsemble"] {
            let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
            let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
            sacAgent.qEnsemble.update(parameters: qParams)
        }
        
        eval(sacAgent.actor, sacAgent.qEnsemble)
        
        lunarLanderContinuousAgent = sacAgent
        
        if let lander = env.unwrapped as? LunarLanderContinuous {
            lunarLanderContinuousSnapshot = lander.currentSnapshot
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
    
    func reset() {
        stopEvaluation()
        loadedAgent = nil
        episodeRewards = []
        episodeSteps = []
        currentEpisode = 0
        currentStep = 0
        episodeReward = 0
        totalReward = 0
        successCount = 0
        
        // FrozenLake
        frozenLakeSnapshot = nil
        frozenLakePolicy = nil
        frozenLakeMap = []
        frozenLakeEnv = nil
        frozenLakeAgent = nil
        
        // CartPole
        cartPoleSnapshot = nil
        cartPoleEnv = nil
        cartPoleAgent = nil
        
        // MountainCar
        mountainCarSnapshot = nil
        mountainCarEnv = nil
        mountainCarAgent = nil
        
        // MountainCarContinuous
        mountainCarContinuousSnapshot = nil
        mountainCarContinuousEnv = nil
        mountainCarContinuousAgent = nil
        
        // Acrobot
        acrobotSnapshot = nil
        acrobotEnv = nil
        acrobotAgent = nil
        
        // Pendulum
        pendulumSnapshot = nil
        pendulumEnv = nil
        pendulumAgent = nil
        
        // LunarLander
        lunarLanderSnapshot = nil
        lunarLanderEnv = nil
        lunarLanderAgent = nil
        
        // LunarLanderContinuous
        lunarLanderContinuousSnapshot = nil
        lunarLanderContinuousEnv = nil
        lunarLanderContinuousAgent = nil
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
            case .mountainCar:
                await runMountainCarEpisode()
            case .mountainCarContinuous:
                await runMountainCarContinuousEpisode()
            case .acrobot:
                await runAcrobotEpisode()
            case .pendulum:
                await runPendulumEpisode()
            case .lunarLander:
                await runLunarLanderEpisode()
            case .lunarLanderContinuous:
                await runLunarLanderContinuousEpisode()
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
    
    private func runMountainCarEpisode() async {
        guard var env = mountainCarEnv, let agent = mountainCarAgent else { return }
        
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
            let action = actionArray[0, 0].item(Int.self)
            
            let result = env.step(action)
            state = result.obs
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            currentStep = steps
            episodeReward = reward
            
            if showVisualization {
                if let mc = env.unwrapped as? MountainCar {
                    mountainCarSnapshot = mc.currentSnapshot
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        mountainCarEnv = env
        episodeRewards.append(reward)
        episodeSteps.append(steps)
        totalReward += reward
        
        if terminated {
            successCount += 1
        }
    }
    
    private func runMountainCarContinuousEpisode() async {
        guard var env = mountainCarContinuousEnv, let agent = mountainCarContinuousAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        let maxSteps = 1000
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            var key = rngKey
            let action = agent.chooseAction(state: state, key: &key, deterministic: true)
            rngKey = key
            
            eval(action)
            
            let result = env.step(action)
            state = result.obs
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward = reward
            }
            
            if showVisualization {
                if let mc = env.unwrapped as? MountainCarContinuous {
                    await MainActor.run {
                        self.mountainCarContinuousSnapshot = mc.currentSnapshot
                    }
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        mountainCarContinuousEnv = env
        
        await MainActor.run {
            self.episodeRewards.append(reward)
            self.episodeSteps.append(steps)
            self.totalReward += reward
            
            if terminated {
                self.successCount += 1
            }
        }
    }
    
    private func runAcrobotEpisode() async {
        guard var env = acrobotEnv, let agent = acrobotAgent else { return }
        
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
                if let acrobot = env.unwrapped as? Acrobot {
                    acrobotSnapshot = acrobot.currentSnapshot
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        acrobotEnv = env
        episodeRewards.append(reward)
        episodeSteps.append(steps)
        totalReward += reward
        
        // Acrobot success: terminated before max steps (reached target height)
        if terminated {
            successCount += 1
        }
    }
    
    private func runPendulumEpisode() async {
        guard var env = pendulumEnv, let agent = pendulumAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        let maxSteps = 200
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            var key = rngKey
            let action = agent.chooseAction(state: state, key: &key, deterministic: true)
            rngKey = key
            
            eval(action)
            
            let result = env.step(action)
            state = result.obs
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward = reward
            }
            
            if showVisualization {
                if let pendulum = env.unwrapped as? Pendulum {
                    await MainActor.run {
                        self.pendulumSnapshot = pendulum.currentSnapshot
                    }
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        pendulumEnv = env
        
        await MainActor.run {
            self.episodeRewards.append(reward)
            self.episodeSteps.append(steps)
            self.totalReward += reward
            
            // Pendulum: good performance if reward > -500
            if reward > -500 {
                self.successCount += 1
            }
        }
    }
    
    private func runLunarLanderEpisode() async {
        guard var env = lunarLanderEnv, let agent = lunarLanderAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        let maxSteps = 1000
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            let qValues = agent.policyNetwork(state.expandedDimensions(axis: 0))
            let action = Int(MLX.argMax(qValues, axis: 1).item(Int32.self))
            
            let result = env.step(action)
            state = result.obs
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward = reward
            }
            
            if showVisualization {
                if let lander = env.unwrapped as? LunarLander {
                    await MainActor.run {
                        self.lunarLanderSnapshot = lander.currentSnapshot
                    }
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        lunarLanderEnv = env
        
        await MainActor.run {
            self.episodeRewards.append(reward)
            self.episodeSteps.append(steps)
            self.totalReward += reward
            
            // LunarLander: successful landing if reward >= 200
            if reward >= 200 {
                self.successCount += 1
            }
        }
    }
    
    private func runLunarLanderContinuousEpisode() async {
        guard var env = lunarLanderContinuousEnv, let agent = lunarLanderContinuousAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        let maxSteps = 1000
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            var key = rngKey
            let action = agent.chooseAction(state: state, key: &key, deterministic: true)
            rngKey = key
            
            eval(action)
            
            let result = env.step(action)
            state = result.obs
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward = reward
            }
            
            if showVisualization {
                if let lander = env.unwrapped as? LunarLanderContinuous {
                    await MainActor.run {
                        self.lunarLanderContinuousSnapshot = lander.currentSnapshot
                    }
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        lunarLanderContinuousEnv = env
        
        await MainActor.run {
            self.episodeRewards.append(reward)
            self.episodeSteps.append(steps)
            self.totalReward += reward
            
            // LunarLander Continuous: successful landing if reward >= 200
            if reward >= 200 {
                self.successCount += 1
            }
        }
    }
}

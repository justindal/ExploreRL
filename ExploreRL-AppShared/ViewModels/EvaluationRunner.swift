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
    
    var deterministicContinuousActions: Bool = true
    
    var episodeRewards: [Double] = []
    var episodeSteps: [Int] = []
    
    private(set) var loadedAgent: SavedAgent?
    
    // FrozenLake
    var frozenLakeSnapshot: FrozenLakeRenderSnapshot?
    var frozenLakePolicy: [Int]?
    var frozenLakeMap: [String] = []
    private var frozenLakeEnv: (any Env<Int, Int>)?
    private var frozenLakeAgent: DiscreteAgent?
    
    // Blackjack
    var blackjackSnapshot: BlackjackRenderSnapshot?
    private var blackjackEnv: (any Env<BlackjackObservation, Int>)?
    private var blackjackAgent: DiscreteAgent?
    
    // Taxi
    var taxiSnapshot: TaxiRenderSnapshot?
    private var taxiEnv: (any Env<Int, Int>)?
    private var taxiAgent: DiscreteAgent?
    
    // CliffWalking
    var cliffWalkingSnapshot: CliffWalkingRenderSnapshot?
    private var cliffWalkingEnv: (any Env<Int, Int>)?
    private var cliffWalkingAgent: DiscreteAgent?
    
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
    
    // CarRacing (continuous)
    var carRacingSnapshot: CarRacingSnapshot?
    private var carRacingEnv: (any Env<MLXArray, MLXArray>)?
    private var carRacingAgent: CarRacingSAC?
    private var carRacingObservationSize: Int = 144
    
    // CarRacingDiscrete
    var carRacingDiscreteSnapshot: CarRacingSnapshot?
    private var carRacingDiscreteEnv: (any Env<MLXArray, Int>)?
    private var carRacingDiscreteAgent: CarRacingDiscreteDQN?
    private var carRacingDiscreteObservationSize: Int = 144
    
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
        case .blackjack:
            try setupBlackjack(agent)
        case .taxi:
            try setupTaxi(agent)
        case .cliffWalking:
            try setupCliffWalking(agent)
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
        case .carRacing:
            try setupCarRacing(agent)
        case .carRacingDiscrete:
            try setupCarRacingDiscrete(agent)
        }
    }
    
    private func setupFrozenLake(_ agent: SavedAgent) throws {
        let mapName = agent.environmentConfig["mapName"] ?? "4x4"
        let isSlippery = agent.environmentConfig["isSlippery"] == "true"
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "100") ?? 100
        
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
        
        guard let env = Gymnazo.make("FrozenLake", maxEpisodeSteps: maxSteps, kwargs: kwargs) as? any Env<Int, Int> else {
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
    
    private func setupBlackjack(_ agent: SavedAgent) throws {
        let natural = agent.environmentConfig["natural"] == "true"
        let sab = agent.environmentConfig["sab"] == "true"
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "100") ?? 100
        
        var kwargs: [String: Any] = [
            "natural": natural,
            "sab": sab
        ]
        
        if showVisualization {
            kwargs["render_mode"] = "rgb_array"
        }
        
        guard let env = Gymnazo.make("Blackjack", maxEpisodeSteps: maxSteps, kwargs: kwargs) as? any Env<BlackjackObservation, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        blackjackEnv = env
        
        let qTable = try AgentStorage.shared.loadQTable(for: agent)
        
        guard let actSpace = env.action_space as? Discrete else {
            throw AgentStorageError.dataCorrupted
        }
        
        let qAgent = QLearningAgent(
            learningRate: 0,
            gamma: 0.99,
            stateSize: BlackjackRunner.stateSize,
            actionSize: actSpace.n,
            epsilon: 0
        )
        
        qAgent.loadQTable(qTable)
        
        blackjackAgent = DiscreteAgent(qAgent)
        
        if let bj = env.unwrapped as? Blackjack {
            blackjackSnapshot = bj.currentSnapshot
        }
    }
    
    private func setupCartPole(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "500") ?? 500
        
        let renderMode: String? = showVisualization ? "human" : nil
        guard var env = Gymnazo.make(
            "CartPole",
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
        eval(dqnAgent.policyNetwork.parameters())
        
        cartPoleAgent = dqnAgent
        
        if let cp = env.unwrapped as? CartPole {
            cartPoleSnapshot = cp.currentSnapshot
        }
    }
    
    private func setupMountainCar(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        let goalVelocity = Double(agent.environmentConfig["goal_velocity"] ?? "0.0") ?? 0.0
        
        var kwargs: [String: Any] = [
            "goal_velocity": goalVelocity
        ]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "MountainCar",
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
        eval(dqnAgent.policyNetwork.parameters())
        
        mountainCarAgent = dqnAgent
        
        if let mc = env.unwrapped as? MountainCar {
            mountainCarSnapshot = mc.currentSnapshot
        }
    }
    
    private func setupMountainCarContinuous(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "999") ?? 999
        let goalVelocity = Double(agent.environmentConfig["goal_velocity"] ?? "0.0") ?? 0.0
        
        var kwargs: [String: Any] = [
            "goal_velocity": goalVelocity
        ]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "MountainCarContinuous",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        mountainCarContinuousEnv = env
        
        let initAlpha = Float(agent.finalEpsilon)
        
        let hiddenSize: Int = {
            if let hs = agent.hyperparameters["hiddenSize"] {
                return max(1, Int(hs.rounded()))
            }
            if let actorArch = agent.networkArchitecture?.first(where: { $0.networkType == "actor" }),
               let hs = actorArch.hiddenSizes.first {
                return hs
            }
            return 256
        }()
        
        let learnedStd: Bool = {
            if let ls = agent.hyperparameters["learnedStd"] { return ls > 0.5 }
            if let sde = agent.hyperparameters["useSDE"] { return sde > 0.5 }
            return true
        }()
        
        let useGSDE: Bool = {
            if let ug = agent.hyperparameters["useGSDE"] { return ug > 0.5 }
            return false
        }()
        
        let sacAgent = MountainCarContinuousSAC(
            hiddenSize: hiddenSize,
            learningRate: 0,
            gamma: 0.99,
            tau: 0.005,
            batchSize: 256,
            bufferSize: 1000,
            learnedStd: learnedStd,
            entCoefMode: .fixed(alpha: initAlpha),
            useGSDE: useGSDE
        )

        let weightsDict = try AgentStorage.shared.loadSACVmapWeights(for: agent)
        
        let excludedActorKeys = Set([
            "actionScale", "actionBias", "epsilon", "logPiConstant",
            "logStdMinArray", "logStdRangeHalf"
        ])
        
        if let actorWeights = weightsDict["actor"], !actorWeights.isEmpty {
            let filteredWeights = actorWeights.filter { !excludedActorKeys.contains($0.key) }
            let actorTuples = filteredWeights.map { ($0.key, $0.value) }
            let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
            sacAgent.actor.update(parameters: actorParams)
        }
        
        if let qEnsembleWeights = weightsDict["qEnsemble"],
           !qEnsembleWeights.isEmpty,
           !qEnsembleWeights.keys.contains(where: { $0.hasPrefix("qf1.") || $0.hasPrefix("qf2.") }) {
            let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
            let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
            sacAgent.qEnsemble.update(parameters: qParams)
            sacAgent.qEnsembleTarget.update(parameters: qParams)
        }
        
        if let entCoefWeights = weightsDict["entCoef"], let logAlpha = entCoefWeights["logAlpha"] {
            sacAgent.logAlphaModule.value = logAlpha
            _ = sacAgent.syncAlpha()
        }
        
        eval(sacAgent.actor, sacAgent.qEnsemble, sacAgent.qEnsembleTarget)
        
        mountainCarContinuousAgent = sacAgent
        
        if let mc = env.unwrapped as? MountainCarContinuous {
            mountainCarContinuousSnapshot = mc.currentSnapshot
        }
    }
    
    private func setupAcrobot(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "500") ?? 500
        
        let renderMode: String? = showVisualization ? "human" : nil
        guard var env = Gymnazo.make(
            "Acrobot",
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
        eval(dqnAgent.policyNetwork.parameters())
        
        acrobotAgent = dqnAgent
        
        if let acrobot = env.unwrapped as? Acrobot {
            acrobotSnapshot = acrobot.currentSnapshot
        }
    }
    
    private func setupPendulum(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        let gravity = Double(agent.environmentConfig["g"] ?? "10.0") ?? 10.0
        
        var kwargs: [String: Any] = [
            "g": gravity
        ]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "Pendulum",
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
            batchSize: 256,
            bufferSize: 1000,
            entCoefMode: .fixed(alpha: Float(agent.finalEpsilon))
        )
        
        let weightsDict = try AgentStorage.shared.loadPendulumWeights(for: agent)
        
        let excludedActorKeys = Set([
            "actionScale", "actionBias", "epsilon", "logPiConstant",
            "logStdMinArray", "logStdRangeHalf"
        ])
        
        if let actorWeights = weightsDict["actor"] {
            let filteredWeights = actorWeights.filter { !excludedActorKeys.contains($0.key) }
            let actorTuples = filteredWeights.map { ($0.key, $0.value) }
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
        let gravity = Double(agent.environmentConfig["gravity"] ?? "-10.0") ?? -10.0
        let enableWind = agent.environmentConfig["enable_wind"] == "true"
        let windPower = Double(agent.environmentConfig["wind_power"] ?? "15.0") ?? 15.0
        let turbulencePower = Double(agent.environmentConfig["turbulence_power"] ?? "1.5") ?? 1.5
        
        var kwargs: [String: Any] = [
            "gravity": gravity,
            "enable_wind": enableWind,
            "wind_power": windPower,
            "turbulence_power": turbulencePower
        ]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "LunarLander",
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
        eval(dqnAgent.policyNetwork.parameters())
        
        lunarLanderAgent = dqnAgent
        
        if let lander = env.unwrapped as? LunarLander {
            lunarLanderSnapshot = lander.currentSnapshot
        }
    }
    
    private func setupLunarLanderContinuous(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        let gravity = Double(agent.environmentConfig["gravity"] ?? "-10.0") ?? -10.0
        let enableWind = agent.environmentConfig["enable_wind"] == "true"
        let windPower = Double(agent.environmentConfig["wind_power"] ?? "15.0") ?? 15.0
        let turbulencePower = Double(agent.environmentConfig["turbulence_power"] ?? "1.5") ?? 1.5
        
        var kwargs: [String: Any] = [
            "gravity": gravity,
            "enable_wind": enableWind,
            "wind_power": windPower,
            "turbulence_power": turbulencePower
        ]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "LunarLanderContinuous",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            throw AgentStorageError.dataCorrupted
        }
        
        _ = env.reset()
        lunarLanderContinuousEnv = env
        
        let (hiddenSize1, hiddenSize2): (Int, Int) = {
            if let h1 = agent.hyperparameters["hiddenSize1"], let h2 = agent.hyperparameters["hiddenSize2"] {
                return (max(1, Int(h1.rounded())), max(1, Int(h2.rounded())))
            }
            if let actorArch = agent.networkArchitecture?.first(where: { $0.networkType == "actor" }),
               actorArch.hiddenSizes.count >= 2 {
                return (actorArch.hiddenSizes[0], actorArch.hiddenSizes[1])
            }
            return (256, 256)
        }()
        
        let sacAgent = LunarLanderContinuousSAC(
            hiddenSize1: hiddenSize1,
            hiddenSize2: hiddenSize2,
            learningRate: 0,
            gamma: 0.99,
            tau: 0.005,
            batchSize: 256,
            bufferSize: 1000,
            entCoefMode: .fixed(alpha: Float(agent.finalEpsilon))
        )
        
        let weightsDict = try AgentStorage.shared.loadLunarLanderContinuousWeights(for: agent)
        let excludedActorKeys = Set([
            "actionScale", "actionBias", "epsilon", "logPiConstant",
            "logStdMinArray", "logStdRangeHalf"
        ])
        
        if let actorWeights = weightsDict["actor"] {
            let filteredWeights = actorWeights.filter { !excludedActorKeys.contains($0.key) }
            let actorTuples = filteredWeights.map { ($0.key, $0.value) }
            let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
            sacAgent.actor.update(parameters: actorParams)
        }
        
        if let qEnsembleWeights = weightsDict["qEnsemble"] {
            let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
            let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
            sacAgent.qEnsemble.update(parameters: qParams)
        }
        
        if let entCoefWeights = weightsDict["entCoef"], let logAlpha = entCoefWeights["logAlpha"] {
            sacAgent.logAlphaModule.value = logAlpha
            _ = sacAgent.syncAlpha()
        }
        
        eval(sacAgent.actor, sacAgent.qEnsemble, sacAgent.logAlphaModule)
        
        lunarLanderContinuousAgent = sacAgent
        
        if let lander = env.unwrapped as? LunarLanderContinuous {
            lunarLanderContinuousSnapshot = lander.currentSnapshot
        }
    }
    
    private func setupCarRacing(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        let lapCompletePercent = Float(agent.environmentConfig["lap_complete_percent"] ?? "0.95") ?? 0.95
        let domainRandomize = agent.environmentConfig["domain_randomize"] == "true"
        let useFrameStack = agent.environmentConfig["useFrameStack"] == "true"
        let frameStackSize = Int(agent.environmentConfig["frameStackSize"] ?? "4") ?? 4
        
        let observationSize = useFrameStack ? 144 * frameStackSize : 144
        carRacingObservationSize = observationSize
        
        var kwargs: [String: Any] = [
            "lap_complete_percent": lapCompletePercent,
            "domain_randomize": domainRandomize
        ]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }

        guard let baseEnv = Gymnazo.make(
            "CarRacing",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? TimeLimit<OrderEnforcing<PassiveEnvChecker<CarRacing>>> else {
            throw AgentStorageError.dataCorrupted
        }

        let resizedEnv = ResizeObservation(
            env: GrayscaleObservation(env: baseEnv),
            shape: (12, 12)
        )

        if useFrameStack {
            var env = FrameStackObservation(env: resizedEnv, stackSize: frameStackSize, paddingType: .reset)
            _ = env.reset()
            carRacingEnv = env
        } else {
            var env = resizedEnv
            _ = env.reset()
            carRacingEnv = env
        }
        
        let sacAgent = CarRacingSAC(
            observationSize: observationSize,
            learningRate: 0,
            gamma: 0.99,
            tau: 0.005,
            batchSize: 256,
            bufferSize: 1000,
            entCoefMode: .fixed(alpha: Float(agent.finalEpsilon))
        )
        
        let weightsDict = try AgentStorage.shared.loadCarRacingWeights(for: agent)

        let excludedActorKeys = Set([
            "actionScale", "actionBias", "epsilon", "logPiConstant",
            "logStdMinArray", "logStdRangeHalf"
        ])
        
        if let actorWeights = weightsDict["actor"] {
            let filteredWeights = actorWeights.filter { !excludedActorKeys.contains($0.key) }
            let actorTuples = filteredWeights.map { ($0.key, $0.value) }
            let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
            sacAgent.actor.update(parameters: actorParams)
        }
        
        if let qEnsembleWeights = weightsDict["qEnsemble"] {
            let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
            let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
            sacAgent.qEnsemble.update(parameters: qParams)
        }
        
        eval(sacAgent.actor, sacAgent.qEnsemble)
        
        carRacingAgent = sacAgent
        
        if let car = carRacingEnv?.unwrapped as? CarRacing {
            carRacingSnapshot = car.currentSnapshot
        }
    }
    
    private func setupCarRacingDiscrete(_ agent: SavedAgent) throws {
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        let lapCompletePercent = Float(agent.environmentConfig["lap_complete_percent"] ?? "0.95") ?? 0.95
        let domainRandomize = agent.environmentConfig["domain_randomize"] == "true"
        let useFrameStack = agent.environmentConfig["useFrameStack"] == "true"
        let frameStackSize = Int(agent.environmentConfig["frameStackSize"] ?? "4") ?? 4
        
        let observationSize = useFrameStack ? 144 * frameStackSize : 144
        carRacingDiscreteObservationSize = observationSize
        
        var kwargs: [String: Any] = [
            "lap_complete_percent": lapCompletePercent,
            "domain_randomize": domainRandomize
        ]
        if showVisualization {
            kwargs["render_mode"] = "human"
        }

        guard let baseEnv = Gymnazo.make(
            "CarRacingDiscrete",
            maxEpisodeSteps: maxSteps,
            kwargs: kwargs
        ) as? TimeLimit<OrderEnforcing<PassiveEnvChecker<CarRacingDiscrete>>> else {
            throw AgentStorageError.dataCorrupted
        }

        let resizedEnv = ResizeObservation(
            env: GrayscaleObservation(env: baseEnv),
            shape: (12, 12)
        )

        if useFrameStack {
            var env = FrameStackObservation(env: resizedEnv, stackSize: frameStackSize, paddingType: .reset)
            _ = env.reset()
            carRacingDiscreteEnv = env
        } else {
            var env = resizedEnv
            _ = env.reset()
            carRacingDiscreteEnv = env
        }
        
        let dqnAgent = CarRacingDiscreteDQN(
            observationSize: observationSize,
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
        
        let weightsDict = try AgentStorage.shared.loadCarRacingDiscreteWeights(for: agent)
        let weightsTuples = weightsDict.map { ($0.key, $0.value) }
        let newParams = NestedDictionary<String, MLXArray>.unflattened(weightsTuples)
        dqnAgent.policyNetwork.update(parameters: newParams)
        eval(dqnAgent.policyNetwork.parameters())
        
        carRacingDiscreteAgent = dqnAgent
        
        if let car = carRacingDiscreteEnv?.unwrapped as? CarRacingDiscrete {
            carRacingDiscreteSnapshot = car.currentSnapshot
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
        
        // Blackjack
        blackjackSnapshot = nil
        blackjackEnv = nil
        blackjackAgent = nil
        
        // Taxi
        taxiSnapshot = nil
        taxiEnv = nil
        taxiAgent = nil
        
        // CliffWalking
        cliffWalkingSnapshot = nil
        cliffWalkingEnv = nil
        cliffWalkingAgent = nil
        
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
        
        // CarRacing
        carRacingSnapshot = nil
        carRacingEnv = nil
        carRacingAgent = nil
        carRacingObservationSize = 144
        
        // CarRacingDiscrete
        carRacingDiscreteSnapshot = nil
        carRacingDiscreteEnv = nil
        carRacingDiscreteAgent = nil
        carRacingDiscreteObservationSize = 144
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
            case .blackjack:
                await runBlackjackEpisode()
            case .taxi:
                await runTaxiEpisode()
            case .cliffWalking:
                await runCliffWalkingEpisode()
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
            case .carRacing:
                await runCarRacingEpisode()
            case .carRacingDiscrete:
                await runCarRacingDiscreteEpisode()
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
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "100") ?? 100
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
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
    
    private func runBlackjackEpisode() async {
        guard var env = blackjackEnv, let agent = blackjackAgent else { return }
        
        let resetResult = env.reset()
        var obs = resetResult.obs
        var state = observationToState(obs)
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        guard let actionSpace = env.action_space as? Discrete else { return }
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "100") ?? 100
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            var key = rngKey
            let action = agent.chooseAction(actionSpace: actionSpace, state: state, key: &key)
            rngKey = key
            
            let result = env.step(action)
            obs = result.obs
            state = observationToState(obs)
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            currentStep = steps
            episodeReward = reward
            
            if showVisualization {
                if let bj = env.unwrapped as? Blackjack {
                    blackjackSnapshot = bj.currentSnapshot
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        blackjackEnv = env
        episodeRewards.append(reward)
        episodeSteps.append(steps)
        totalReward += reward
        
        if reward > 0 {
            successCount += 1
        }
    }
    
    /// Convert BlackjackObservation to a single integer state index
    private func observationToState(_ obs: BlackjackObservation) -> Int {
        return obs.playerSum * 22 + obs.dealerCard * 2 + obs.usableAce
    }
    
    private func setupTaxi(_ agent: SavedAgent) throws {
        let isRainy = agent.environmentConfig["isRainy"] == "true"
        let ficklePassenger = agent.environmentConfig["ficklePassenger"] == "true"
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        
        var kwargs: [String: Any] = [
            "is_rainy": isRainy,
            "fickle_passenger": ficklePassenger
        ]
        
        if showVisualization {
            kwargs["render_mode"] = "rgb_array"
        }
        
        guard let env = Gymnazo.make("Taxi", maxEpisodeSteps: maxSteps, kwargs: kwargs) as? any Env<Int, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        taxiEnv = env
        
        let qTable = try AgentStorage.shared.loadQTable(for: agent)
        
        guard let obsSpace = env.observation_space as? Discrete,
              let actSpace = env.action_space as? Discrete else {
            throw AgentStorageError.dataCorrupted
        }
        
        let qAgent = QLearningAgent(
            learningRate: 0,
            gamma: 0.99,
            stateSize: obsSpace.n,
            actionSize: actSpace.n,
            epsilon: 0
        )
        
        qAgent.loadQTable(qTable)
        
        taxiAgent = DiscreteAgent(qAgent)
        
        if let taxi = env.unwrapped as? Taxi {
            taxiSnapshot = taxi.currentSnapshot
        }
    }
    
    private func runTaxiEpisode() async {
        guard var env = taxiEnv, let agent = taxiAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        guard let actionSpace = env.action_space as? Discrete else { return }
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
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
                if let taxi = env.unwrapped as? Taxi {
                    taxiSnapshot = taxi.currentSnapshot
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        taxiEnv = env
        episodeRewards.append(reward)
        episodeSteps.append(steps)
        totalReward += reward
        
        // Taxi success: passenger delivered (episode terminates with positive reward)
        if terminated && reward > 0 {
            successCount += 1
        }
    }
    
    private func setupCliffWalking(_ agent: SavedAgent) throws {
        let isSlippery = agent.environmentConfig["isSlippery"] == "true"
        let maxSteps = Int(agent.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        
        var kwargs: [String: Any] = [
            "is_slippery": isSlippery
        ]
        
        if showVisualization {
            kwargs["render_mode"] = "rgb_array"
        }
        
        guard let env = Gymnazo.make("CliffWalking", maxEpisodeSteps: maxSteps, kwargs: kwargs) as? any Env<Int, Int> else {
            throw AgentStorageError.dataCorrupted
        }
        cliffWalkingEnv = env
        
        let qTable = try AgentStorage.shared.loadQTable(for: agent)
        
        guard let obsSpace = env.observation_space as? Discrete,
              let actSpace = env.action_space as? Discrete else {
            throw AgentStorageError.dataCorrupted
        }
        
        let qAgent = QLearningAgent(
            learningRate: 0,
            gamma: 0.99,
            stateSize: obsSpace.n,
            actionSize: actSpace.n,
            epsilon: 0
        )
        
        qAgent.loadQTable(qTable)
        
        cliffWalkingAgent = DiscreteAgent(qAgent)
        
        if let cliff = env.unwrapped as? CliffWalking {
            cliffWalkingSnapshot = cliff.currentSnapshot
        }
    }
    
    private func runCliffWalkingEpisode() async {
        guard var env = cliffWalkingEnv, let agent = cliffWalkingAgent else { return }
        
        let resetResult = env.reset()
        var state = resetResult.obs
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        guard let actionSpace = env.action_space as? Discrete else { return }
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
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
                if let cliff = env.unwrapped as? CliffWalking {
                    cliffWalkingSnapshot = cliff.currentSnapshot
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        cliffWalkingEnv = env
        episodeRewards.append(reward)
        episodeSteps.append(steps)
        totalReward += reward
        
        // CliffWalking success: agent reaches the goal (episode terminates)
        if terminated {
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
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        
        let sdeSampleFreq = Int(loadedAgent?.hyperparameters["sdeSampleFreq"] ?? -1)
        if !deterministicContinuousActions, agent.actor.useGSDE {
            agent.actor.resetNoise(key: &rngKey)
        }
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            if !deterministicContinuousActions, agent.actor.useGSDE, sdeSampleFreq > 0, steps > 0, (steps % sdeSampleFreq == 0) {
                agent.actor.resetNoise(key: &rngKey)
            }
            
            var key = rngKey
            let action = agent.chooseAction(state: state, key: &key, deterministic: deterministicContinuousActions)
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
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "200") ?? 200
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            var key = rngKey
            let action = agent.chooseAction(state: state, key: &key, deterministic: deterministicContinuousActions)
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
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        
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
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            var key = rngKey
            let action = agent.chooseAction(state: state, key: &key, deterministic: deterministicContinuousActions)
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

    private func preprocessCarRacingObservation(_ obs: MLXArray, size: Int) -> MLXArray {
        let x = obs.asType(.float32) / MLXArray(Float32(255.0))
        return x.reshaped([size])
    }
    
    private func runCarRacingEpisode() async {
        guard var env = carRacingEnv, let agent = carRacingAgent else { return }
        
        let resetResult = env.reset()
        var state = preprocessCarRacingObservation(resetResult.obs, size: carRacingObservationSize)
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000

        if !deterministicContinuousActions, agent.actor.useSDE {
            let (newKey, noiseKey) = MLX.split(key: rngKey)
            rngKey = newKey
            agent.actor.resetNoise(key: noiseKey)
        }
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            var key = rngKey
            let action = agent.chooseAction(state: state, key: &key, deterministic: deterministicContinuousActions)
            rngKey = key
            
            eval(action)
            
            let result = env.step(action)
            state = preprocessCarRacingObservation(result.obs, size: carRacingObservationSize)
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward = reward
            }
            
            if showVisualization {
                if let car = env.unwrapped as? CarRacing {
                    await MainActor.run {
                        self.carRacingSnapshot = car.currentSnapshot
                    }
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        carRacingEnv = env
        
        await MainActor.run {
            self.episodeRewards.append(reward)
            self.episodeSteps.append(steps)
            self.totalReward += reward
            
            // CarRacing: successful lap if reward >= 900
            if reward >= 900 {
                self.successCount += 1
            }
        }
    }
    
    private func runCarRacingDiscreteEpisode() async {
        guard var env = carRacingDiscreteEnv, let agent = carRacingDiscreteAgent else { return }
        
        let resetResult = env.reset()
        var state = preprocessCarRacingObservation(resetResult.obs, size: carRacingDiscreteObservationSize)
        var terminated = false
        var truncated = false
        var steps = 0
        var reward = 0.0
        
        let maxSteps = Int(loadedAgent?.environmentConfig["maxStepsPerEpisode"] ?? "1000") ?? 1000
        
        while !terminated && !truncated && isRunning && steps < maxSteps {
            let qValues = agent.policyNetwork(state.expandedDimensions(axis: 0))
            let action = Int(MLX.argMax(qValues, axis: 1).item(Int32.self))
            
            let result = env.step(action)
            state = preprocessCarRacingObservation(result.obs, size: carRacingDiscreteObservationSize)
            terminated = result.terminated
            truncated = result.truncated
            reward += result.reward
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward = reward
            }
            
            if showVisualization {
                if let car = env.unwrapped as? CarRacingDiscrete {
                    await MainActor.run {
                        self.carRacingDiscreteSnapshot = car.currentSnapshot
                    }
                }
                
                let delayNs = UInt64(1_000_000_000 / targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        carRacingDiscreteEnv = env
        
        await MainActor.run {
            self.episodeRewards.append(reward)
            self.episodeSteps.append(steps)
            self.totalReward += reward
            
            // CarRacingDiscrete: successful lap if reward >= 900
            if reward >= 900 {
                self.successCount += 1
            }
        }
    }
}

//
//  FrozenLakeRunner.swift
//

import SwiftUI
import Gymnazo
import MLX

@MainActor
@Observable class FrozenLakeRunner: SavableEnvironmentRunner {
    var snapshot: FrozenLakeRenderSnapshot?
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
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        return recentEpisodes.map { $0.reward }.reduce(0, +) / Double(recentEpisodes.count)
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? 0
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .frozenLake }
    static var displayName: String { "Frozen Lake" }
    static var algorithmName: String { "Q-Learning / SARSA" }
    static var icon: String { "snowflake" }
    static var accentColor: Color { .cyan }
    static var category: EnvironmentCategory { .toyText }
    
    var currentPolicy: [Int]?
    var totalReward = 0.0
    var currentMap: [String] = []
    var turboMode: Bool = TrainingDefaults.turboMode
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    var mapName: String = "4x4"
    var customMapSize: Int = 8
    var isSlippery: Bool = false
    var isLoadingAgent: Bool = false
    var maxStepsPerEpisode: Int = 100
    var movingAverageWindow = 100
    
    var selectedAlgorithm: TabularAlgorithm = .qLearning {
        didSet {
            guard !isLoadingAgent else { return }
            resetToDefaults()
            reset()
        }
    }
    
    var showPolicy: Bool = false {
        didSet {
            updateSnapshot()
        }
    }
    
    // Hyperparameters
    var learningRate: Float = 0.8
    var gamma: Float = 0.95
    var epsilon: Float = 1.0
    var minEpsilon: Float = 0.01
    var epsilonDecay: Float = 0.995
    
    private var episodesCompletedInRun: Int = 0
    
    private var env: (any Env<Int, Int>)?
    private var agent: DiscreteAgent?
    private var rngKey: MLXArray
    
    
    var successRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let successes = recentEpisodes.filter { $0.success }.count
        return Double(successes) / Double(recentEpisodes.count)
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
    
    var currentMapSize: Int {
        if mapName == "Custom" {
            return customMapSize
        }
        return mapName == "8x8" ? 8 : 4
    }
    
    
    init() {
        self.rngKey = MLX.key(0)
        setupEnvironment()
    }
    
    
    func setupEnvironment(withMap savedMap: [String]? = nil) {
        var kwargs: [String: Any] = [
            "is_slippery": isSlippery,
            "map_name": mapName
        ]
        
        if renderEnabled {
            kwargs["render_mode"] = "rgb_array"
        }
        
        var desc: [String]
        if let savedMap = savedMap, !savedMap.isEmpty {
            desc = savedMap
        } else if mapName == "Custom" {
            desc = FrozenLake.generateRandomMap(size: customMapSize)
        } else {
            desc = FrozenLake.MAPS[mapName] ?? FrozenLake.MAPS["4x4"]!
        }
        
        kwargs["desc"] = desc
        self.currentMap = desc
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(UInt64(Date().timeIntervalSince1970))
        }
        
        guard let madeEnv = Gymnazo.make(
            "FrozenLake",
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
        
        switch selectedAlgorithm {
        case .qLearning:
            let qAgent = QLearningAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: obsSpace.n,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            self.agent = DiscreteAgent(qAgent)
        case .sarsa:
            let sarsaAgent = SARSAAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: obsSpace.n,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            self.agent = DiscreteAgent(sarsaAgent)
        }
        
        _ = self.env?.reset()
        updateSnapshot()
        
        episodeMetrics.removeAll()
        committedEpisodeMetricsCount = 0
        totalReward = 0
        episodeCount = 1
        currentStep = 0
        episodeReward = 0
    }
    
    func setupEnvironment() {
        setupEnvironment(withMap: nil)
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
        self.epsilon = 1.0
        
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = 0
        trainingCompletedNormally = false
        committedEpisodeMetricsCount = 0
        
        setupEnvironment()
    }
    
    func resetToDefaults() {
        let defaults = selectedAlgorithm.defaults
        self.learningRate = defaults.learningRate
        self.gamma = defaults.gamma
        self.epsilon = defaults.epsilon
        self.epsilonDecay = defaults.epsilonDecay
    }
    
    
    func saveAgent(name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        let mapDataString: String
        if let mapData = try? JSONEncoder().encode(currentMap),
           let mapString = String(data: mapData, encoding: .utf8) {
            mapDataString = mapString
        } else {
            mapDataString = "[]"
        }
        
        let saved = try AgentStorage.shared.saveFrozenLakeAgent(
            name: name,
            qTable: agent.qTable,
            algorithm: selectedAlgorithm.rawValue,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            epsilon: Double(epsilon),
            bestReward: combinedBestReward,
            averageReward: averageReward,
            successRate: successRate,
            hyperparameters: [
                "learningRate": Double(learningRate),
                "gamma": Double(gamma),
                "epsilon": Double(epsilon),
                "epsilonDecay": Double(epsilonDecay),
                "minEpsilon": Double(minEpsilon)
            ],
            environmentConfig: [
                "maxStepsPerEpisode": "\(maxStepsPerEpisode)",
                "mapName": mapName,
                "mapSize": mapName == "Custom" ? "\(customMapSize)" : mapName,
                "isSlippery": isSlippery ? "true" : "false",
                "mapData": mapDataString
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
        
        try AgentStorage.shared.updateFrozenLakeAgent(
            id: id,
            newName: name,
            qTable: agent.qTable,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            epsilon: Double(epsilon),
            bestReward: combinedBestReward,
            averageReward: averageReward,
            successRate: successRate,
            hyperparameters: [
                "learningRate": Double(learningRate),
                "gamma": Double(gamma),
                "epsilon": Double(epsilon),
                "epsilonDecay": Double(epsilonDecay),
                "minEpsilon": Double(minEpsilon)
            ]
        )
        
        loadedAgentName = name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = totalEpisodesTrained
        committedEpisodeMetricsCount = episodeMetrics.count
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .frozenLake else {
            throw AgentStorageError.wrongEnvironmentType
        }
        
        stopTraining()
        accumulatedTrainingTimeSeconds = savedAgent.trainingTimeSeconds ?? 0
        trainingSessionStartDate = nil
        
        isLoadingAgent = true
        defer { isLoadingAgent = false }
        
        if let algorithm = TabularAlgorithm(rawValue: savedAgent.algorithmType) {
            selectedAlgorithm = algorithm
        }
        
        if let lr = savedAgent.hyperparameters["learningRate"] { learningRate = Float(lr) }
        if let g = savedAgent.hyperparameters["gamma"] { gamma = Float(g) }
        if let eps = savedAgent.hyperparameters["epsilon"] { epsilon = Float(eps) }
        if let decay = savedAgent.hyperparameters["epsilonDecay"] { epsilonDecay = Float(decay) }
        if let minEps = savedAgent.hyperparameters["minEpsilon"] { minEpsilon = Float(minEps) }
        
        if let mapNameConfig = savedAgent.environmentConfig["mapName"] { mapName = mapNameConfig }
        if let slippery = savedAgent.environmentConfig["isSlippery"] { isSlippery = slippery == "true" }
        if let maxSteps = savedAgent.environmentConfig["maxStepsPerEpisode"], let steps = Int(maxSteps) {
            maxStepsPerEpisode = steps
        }
        if mapName == "Custom", let sizeStr = savedAgent.environmentConfig["mapSize"],
           let size = Int(sizeStr) {
            customMapSize = size
        }
        
        var savedMap: [String]? = nil
        if let mapDataString = savedAgent.environmentConfig["mapData"],
           let mapData = mapDataString.data(using: .utf8),
           let decodedMap = try? JSONDecoder().decode([String].self, from: mapData),
           !decodedMap.isEmpty {
            savedMap = decodedMap
        }
        
        setupEnvironment(withMap: savedMap)
        
        let qTable = try AgentStorage.shared.loadQTable(for: savedAgent)
        
        guard let obsSpace = env?.observation_space as? Discrete,
              let actSpace = env?.action_space as? Discrete else {
            throw AgentStorageError.dataCorrupted
        }
        
        switch savedAgent.algorithmType {
        case "Q-Learning":
            let qAgent = QLearningAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: obsSpace.n,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            qAgent.loadQTable(qTable)
            self.agent = DiscreteAgent(qAgent)
            
        case "SARSA":
            let sarsaAgent = SARSAAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: obsSpace.n,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            sarsaAgent.loadQTable(qTable)
            self.agent = DiscreteAgent(sarsaAgent)
            
        default:
            throw AgentStorageError.dataCorrupted
        }
        
        episodeMetrics = []
        committedEpisodeMetricsCount = 0
        episodeCount = savedAgent.episodesTrained + 1
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
        
        updateSnapshot()
    }
    
    
    private func runTrainingLoop() async {
        let targetEpisodes = episodeCount + episodesPerRun
        
        var lastUIUpdate = Date()
        let uiUpdateInterval: TimeInterval = renderEnabled ? 1.0 / 30.0 : 1.0 / 5.0
        
        for episode in episodeCount..<targetEpisodes {
            if !isTraining { break }
            
            guard var env = self.env, let agent = self.agent else { break }
            
            let resetResult = env.reset()
            var currentState = resetResult.obs

            guard let actionSpace = env.action_space as? Discrete else { break }
            var key = self.rngKey
            var action = agent.chooseAction(
                actionSpace: actionSpace,
                state: currentState,
                key: &key
            )
            self.rngKey = key
            
            var terminated = false
            var truncated = false
            var steps = 0
            var episodeRewardLocal = 0.0
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
                
                let result = env.step(action)
                let nextState = result.obs
                let reward = Float(result.reward)
                
                var currentKey = self.rngKey
                let nextAction = agent.chooseAction(
                    actionSpace: actionSpace,
                    state: nextState,
                    key: &currentKey
                )
                self.rngKey = currentKey
                
                let updateResult = agent.update(
                    state: currentState,
                    action: action,
                    reward: reward,
                    nextState: nextState,
                    nextAction: nextAction,
                    terminated: result.terminated
                )
                
                totalTDError += Double(abs(updateResult.tdError))
                
                currentState = nextState
                action = nextAction
                terminated = result.terminated
                truncated = result.truncated
                steps += 1
                episodeRewardLocal += result.reward
                
                if !turboMode {
                    if renderEnabled {
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
                            self.episodeReward = episodeRewardLocal
                        }
                        
                        let delayNs = UInt64(1_000_000_000 / self.targetFPS)
                        try? await Task.sleep(nanoseconds: delayNs)
                    } else {
                        let now = Date()
                        if now.timeIntervalSince(lastUIUpdate) >= uiUpdateInterval {
                            self.currentStep = steps
                            self.episodeReward = episodeRewardLocal
                            lastUIUpdate = now
                            await Task.yield()
                        }
                    }
                } else if terminated || truncated {
                    self.currentStep = steps
                    self.episodeReward = episodeRewardLocal
                }
            }
            
            let episodeCompleted = terminated || truncated
            if !episodeCompleted {
                self.currentStep = 0
                self.episodeReward = 0
                break
            }
            
            let avgTDError = totalTDError / Double(max(1, steps))
            
            let qTable = agent.qTable
            let maxQPerState = qTable.max(axis: 1)
            let avgMaxQ = (maxQPerState.mean().item() as Float)
            
            let success = episodeRewardLocal > 0
            let completedEpisodeNumber = loadedEpisodeCount + uncommittedEpisodeCount + 1
            let metric = EpisodeMetrics(
                episode: completedEpisodeNumber,
                reward: episodeRewardLocal,
                steps: steps,
                success: success,
                averageTDError: avgTDError,
                averageLoss: nil,
                averageMaxQ: Double(avgMaxQ),
                epsilon: Double(epsilon),
                alpha: nil,
                averageGradNorm: nil,
                rewardMovingAverage: nil
            )
            
            self.episodeMetrics.append(metric)
            self.episodesCompletedInRun += 1
            if success {
                self.totalReward += episodeRewardLocal
            }
            
            if epsilon > minEpsilon {
                epsilon = max(minEpsilon, epsilon * epsilonDecay)
                self.agent?.epsilon = epsilon
            }
            
            if turboMode {
                await Task.yield()
            }
        }
        
        if self.isTraining {
            self.trainingCompletedNormally = true
        }
        self.stopTraining()
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

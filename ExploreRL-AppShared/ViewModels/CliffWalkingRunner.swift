//
//  CliffWalkingRunner.swift
//

import SwiftUI
import Gymnazo
import MLX

@MainActor
@Observable class CliffWalkingRunner: SavableEnvironmentRunner {
    var snapshot: CliffWalkingRenderSnapshot?
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
    private var loadedBestReward: Double = -1000
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
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -1000
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .cliffWalking }
    static var displayName: String { "Cliff Walking" }
    static var algorithmName: String { "Q-Learning / SARSA" }
    static var icon: String { "arrow.triangle.turn.up.right.diamond" }
    static var accentColor: Color { .brown }
    static var category: EnvironmentCategory { .toyText }
    
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    var isSlippery: Bool = false
    var isLoadingAgent: Bool = false
    var maxStepsPerEpisode: Int = 200
    var movingAverageWindow = 100
    
    var selectedAlgorithm: TabularAlgorithm = .qLearning {
        didSet {
            guard !isLoadingAgent else { return }
            resetToDefaults()
            reset()
        }
    }
    
    // Hyperparameters
    var learningRate: Float = 0.1
    var gamma: Float = 0.99
    var epsilon: Float = 1.0
    var minEpsilon: Float = 0.01
    var epsilonDecay: Float = 0.995
    
    private var episodesCompletedInRun: Int = 0
    
    private var env: (any Env<Int, Int>)?
    private var agent: DiscreteAgent?
    private var rngKey: MLXArray
    
    // State space: 48 discrete states (4 rows x 12 columns)
    static let stateSize = 48
    static let actionSize = 4
    
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
    
    init() {
        self.rngKey = MLX.key(0)
        setupEnvironment()
    }
    
    func setupEnvironment() {
        var kwargs: [String: Any] = [
            "is_slippery": isSlippery
        ]
        
        if renderEnabled {
            kwargs["render_mode"] = "rgb_array"
        }
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(UInt64(Date().timeIntervalSince1970))
        }
        
        guard let madeEnv = Gymnazo.make(
            "CliffWalking",
            kwargs: kwargs
        ) as? any Env<Int, Int> else {
            print("Failed to create CliffWalking environment")
            return
        }
        
        self.env = madeEnv
        
        guard let obsSpace = madeEnv.observation_space as? Discrete,
              let actSpace = madeEnv.action_space as? Discrete else {
            print("CliffWalking spaces mismatch")
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
    
    private func updateSnapshot() {
        if let cliff = self.env?.unwrapped as? CliffWalking {
            self.snapshot = cliff.currentSnapshot
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
        loadedBestReward = -1000
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
        
        let saved = try AgentStorage.shared.saveCliffWalkingAgent(
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
                "isSlippery": isSlippery ? "true" : "false"
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
        
        try AgentStorage.shared.updateCliffWalkingAgent(
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
        guard savedAgent.environmentType == .cliffWalking else {
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
        
        if let slipperyConfig = savedAgent.environmentConfig["isSlippery"] { isSlippery = slipperyConfig == "true" }
        if let maxSteps = savedAgent.environmentConfig["maxStepsPerEpisode"], let steps = Int(maxSteps) {
            maxStepsPerEpisode = steps
        }
        
        setupEnvironment()
        
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
                        if let cliff = env.unwrapped as? CliffWalking {
                            self.snapshot = cliff.currentSnapshot
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
            
            // Success is when the agent reaches the goal (episode terminates without hitting cliff at the end)
            // In CliffWalking, termination happens only when reaching the goal (state 47)
            let success = terminated && episodeRewardLocal > -100
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
            self.totalReward += episodeRewardLocal
            
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


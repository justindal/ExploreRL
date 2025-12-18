//
//  BlackjackRunner.swift
//

import SwiftUI
import Gymnazo
import MLX

@MainActor
@Observable class BlackjackRunner: SavableEnvironmentRunner {
    var snapshot: BlackjackRenderSnapshot?
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
        let newBest = episodeMetrics.map { $0.reward }.max() ?? 0
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .blackjack }
    static var displayName: String { "Blackjack" }
    static var algorithmName: String { "Q-Learning / SARSA" }
    static var icon: String { "suit.spade.fill" }
    static var accentColor: Color { .mint }
    static var category: EnvironmentCategory { .toyText }
    
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    var natural: Bool = false
    var sab: Bool = false
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
    
    // Hyperparameters
    var learningRate: Float = 0.1
    var gamma: Float = 0.99
    var epsilon: Float = 1.0
    var minEpsilon: Float = 0.01
    var epsilonDecay: Float = 0.9995
    
    private var episodesCompletedInRun: Int = 0
    
    private var env: (any Env<BlackjackObservation, Int>)?
    private var agent: DiscreteAgent?
    private var rngKey: MLXArray
    
    // State space dimensions for Blackjack
    // playerSum: 0-31 (32 values), dealerCard: 0-10 (11 values), usableAce: 0-1 (2 values)
    // Total: 32 * 11 * 2 = 704 states
    static let stateSize = 32 * 11 * 2
    static let actionSize = 2
    
    /// Convert BlackjackObservation to a single integer state index
    private func observationToState(_ obs: BlackjackObservation) -> Int {
        // index = playerSum * 22 + dealerCard * 2 + usableAce
        return obs.playerSum * 22 + obs.dealerCard * 2 + obs.usableAce
    }
    
    var winRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let wins = recentEpisodes.filter { $0.reward > 0 }.count
        return Double(wins) / Double(recentEpisodes.count)
    }
    
    var lossRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let losses = recentEpisodes.filter { $0.reward < 0 }.count
        return Double(losses) / Double(recentEpisodes.count)
    }
    
    var drawRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recentEpisodes = episodeMetrics.suffix(movingAverageWindow)
        let draws = recentEpisodes.filter { $0.reward == 0 }.count
        return Double(draws) / Double(recentEpisodes.count)
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
            "natural": natural,
            "sab": sab
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
            "Blackjack",
            kwargs: kwargs
        ) as? any Env<BlackjackObservation, Int> else {
            print("Failed to create Blackjack environment")
            return
        }
        
        self.env = madeEnv
        
        guard let actSpace = madeEnv.action_space as? Discrete else {
            print("Blackjack action space mismatch")
            return
        }
        
        switch selectedAlgorithm {
        case .qLearning:
            let qAgent = QLearningAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: Self.stateSize,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            self.agent = DiscreteAgent(qAgent)
        case .sarsa:
            let sarsaAgent = SARSAAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: Self.stateSize,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            self.agent = DiscreteAgent(sarsaAgent)
        }
        
        _ = self.env?.reset()
        updateSnapshot()
        
        episodeMetrics.removeAll()
        totalReward = 0
        episodeCount = 1
        currentStep = 0
        episodeReward = 0
    }
    
    private func updateSnapshot() {
        if let blackjack = self.env?.unwrapped as? Blackjack {
            self.snapshot = blackjack.currentSnapshot
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
        
        let saved = try AgentStorage.shared.saveBlackjackAgent(
            name: name,
            qTable: agent.qTable,
            algorithm: selectedAlgorithm.rawValue,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            epsilon: Double(epsilon),
            bestReward: combinedBestReward,
            averageReward: averageReward,
            winRate: winRate,
            hyperparameters: [
                "learningRate": Double(learningRate),
                "gamma": Double(gamma),
                "epsilon": Double(epsilon),
                "epsilonDecay": Double(epsilonDecay),
                "minEpsilon": Double(minEpsilon)
            ],
            environmentConfig: [
                "natural": natural ? "true" : "false",
                "sab": sab ? "true" : "false"
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
        
        try AgentStorage.shared.updateBlackjackAgent(
            id: id,
            newName: name,
            qTable: agent.qTable,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            epsilon: Double(epsilon),
            bestReward: combinedBestReward,
            averageReward: averageReward,
            winRate: winRate,
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
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .blackjack else {
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
        
        if let naturalConfig = savedAgent.environmentConfig["natural"] { natural = naturalConfig == "true" }
        if let sabConfig = savedAgent.environmentConfig["sab"] { sab = sabConfig == "true" }
        
        setupEnvironment()
        
        let qTable = try AgentStorage.shared.loadQTable(for: savedAgent)
        
        guard let actSpace = env?.action_space as? Discrete else {
            throw AgentStorageError.dataCorrupted
        }
        
        switch savedAgent.algorithmType {
        case "Q-Learning":
            let qAgent = QLearningAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: Self.stateSize,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            qAgent.loadQTable(qTable)
            self.agent = DiscreteAgent(qAgent)
            
        case "SARSA":
            let sarsaAgent = SARSAAgent(
                learningRate: learningRate,
                gamma: gamma,
                stateSize: Self.stateSize,
                actionSize: actSpace.n,
                epsilon: epsilon
            )
            sarsaAgent.loadQTable(qTable)
            self.agent = DiscreteAgent(sarsaAgent)
            
        default:
            throw AgentStorageError.dataCorrupted
        }
        
        episodeMetrics = []
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
            var currentObs = resetResult.obs
            var currentState = observationToState(currentObs)

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
                let nextObs = result.obs
                let nextState = observationToState(nextObs)
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
                
                currentObs = nextObs
                currentState = nextState
                action = nextAction
                terminated = result.terminated
                truncated = result.truncated
                steps += 1
                episodeRewardLocal += result.reward
                
                if !turboMode {
                    if renderEnabled {
                        if let blackjack = env.unwrapped as? Blackjack {
                            self.snapshot = blackjack.currentSnapshot
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
            let completedEpisodeNumber = loadedEpisodeCount + episodeMetrics.count + 1
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


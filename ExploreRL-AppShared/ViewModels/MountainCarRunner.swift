//
//  MountainCarRunner.swift
//

import SwiftUI
import Gymnazo
import MLX
import MLXNN

@MainActor
@Observable class MountainCarRunner: SavableEnvironmentRunner {
    var snapshot: MountainCarSnapshot?
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
        let recent = episodeMetrics.suffix(movingAverageWindow)
        return recent.map { $0.reward }.reduce(0, +) / Double(recent.count)
    }
    
    var combinedBestReward: Double {
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -200
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .mountainCar }
    static var displayName: String { "Mountain Car" }
    static var algorithmName: String { "DQN" }
    static var icon: String { "car.side" }
    static var accentColor: Color { .green }
    static var category: EnvironmentCategory { .classicControl }
    
    var isRunning = false
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    var movingAverageWindow = 50
    
    var learningRate: Double = Double(MountainCarDQN.Defaults.learningRate)
    var gamma: Double = Double(MountainCarDQN.Defaults.gamma)
    var epsilon: Double = Double(MountainCarDQN.Defaults.epsilonStart)
    var epsilonDecaySteps: Int = MountainCarDQN.Defaults.epsilonDecaySteps
    var epsilonMin: Double = Double(MountainCarDQN.Defaults.epsilonEnd)
    var batchSize: Int = MountainCarDQN.Defaults.batchSize
    var targetUpdateFrequency: Int = MountainCarDQN.Defaults.targetUpdateFrequency
    var warmupSteps: Int = TrainingDefaults.warmupSteps
    var bufferSize: Int = MountainCarDQN.Defaults.bufferCapacity
    var gradClipNorm: Double = Double(MountainCarDQN.Defaults.gradClipNorm)
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    var maxStepsPerEpisode: Int = 200
    
    var goalVelocity: Double = 0.0
    
    var useRewardShaping: Bool = true
    var velocityShapingCoef: Double = 10.0
    var positionShapingCoef: Double = 10.0
    var successBonusReward: Double = 100.0
    
    var earlyStopEnabled: Bool = TrainingDefaults.earlyStopEnabled
    var earlyStopWindow: Int = TrainingDefaults.earlyStopWindow
    var earlyStopRewardThreshold: Double = -110
    
    var clipReward: Bool = TrainingDefaults.clipReward
    var clipRewardMin: Double = TrainingDefaults.clipRewardMin
    var clipRewardMax: Double = TrainingDefaults.clipRewardMax
    
    var position: Float = -0.5
    var velocity: Float = 0.0
    
    private var episodesCompletedInRun: Int = 0
    private var env: (any Env<MLXArray, Int>)?
    private var rngKey: MLXArray
    private var agent: MountainCarDQN?
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
        var kwargs: [String: Any] = [
            "goal_velocity": goalVelocity
        ]
        if renderEnabled {
            kwargs["render_mode"] = "human"
        }
        
        guard let baseEnv = Gymnazo.make(
            "MountainCar",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: kwargs
        ) as? TimeLimit<OrderEnforcing<PassiveEnvChecker<MountainCar>>> else {
            print("Failed to create MountainCar environment")
            return
        }
        
        if useRewardShaping {
            let velCoef = velocityShapingCoef
            let posCoef = positionShapingCoef
            let successBonus = successBonusReward
            
            var shapedEnv = baseEnv.rewardsShaped { reward, obs, terminated in
                let pos = Double(obs[0].item(Float.self))
                let vel = Double(obs[1].item(Float.self))
                var shaped = reward
                shaped += Swift.abs(vel) * velCoef
                if pos > -0.4 {
                    shaped += (pos + 0.4) * posCoef
                }
                if terminated {
                    shaped += successBonus
                }
                return shaped
            }
            _ = shapedEnv.reset()
            self.env = shapedEnv
        } else {
            var env = baseEnv
            _ = env.reset()
            self.env = env
        }
        updateSnapshot()
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(0)
        }
        
        if agent == nil {
            agent = MountainCarDQN(
                learningRate: Float(learningRate),
                gamma: Float(gamma),
                epsilonStart: Float(epsilon),
                epsilonEnd: Float(epsilonMin),
                epsilonDecaySteps: epsilonDecaySteps,
                targetUpdateFrequency: targetUpdateFrequency,
                batchSize: batchSize,
                bufferCapacity: bufferSize,
                gradClipNorm: Float(gradClipNorm)
            )
        }
        
        episodeMetrics.removeAll()
        committedEpisodeMetricsCount = 0
        totalReward = 0
        episodeCount = 1
        currentStep = 0
        episodeReward = 0
        totalSteps = 0
        episodesCompletedInRun = 0
    }
    
    private func updateSnapshot() {
        if let mountainCar = self.env?.unwrapped as? MountainCar {
            self.snapshot = mountainCar.currentSnapshot
            self.position = snapshot?.position ?? -0.5
            self.velocity = snapshot?.velocity ?? 0.0
        }
    }
    
    func reset() {
        stopTraining()
        stopRunning()
        accumulatedTrainingTimeSeconds = 0
        trainingSessionStartDate = nil
        agent = nil
        episodeMetrics = []
        totalSteps = 0
        epsilon = Double(MountainCarDQN.Defaults.epsilonStart)
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
        learningRate = Double(MountainCarDQN.Defaults.learningRate)
        gamma = Double(MountainCarDQN.Defaults.gamma)
        epsilon = Double(MountainCarDQN.Defaults.epsilonStart)
        epsilonDecaySteps = MountainCarDQN.Defaults.epsilonDecaySteps
        epsilonMin = Double(MountainCarDQN.Defaults.epsilonEnd)
        batchSize = MountainCarDQN.Defaults.batchSize
        targetUpdateFrequency = MountainCarDQN.Defaults.targetUpdateFrequency
        gradClipNorm = Double(MountainCarDQN.Defaults.gradClipNorm)
        bufferSize = MountainCarDQN.Defaults.bufferCapacity
        
        warmupSteps = TrainingDefaults.warmupSteps
        renderEnabled = TrainingDefaults.renderEnabled
        episodesPerRun = TrainingDefaults.episodesPerRun
        episodesCompletedInRun = 0
        useSeed = TrainingDefaults.useSeed
        seed = TrainingDefaults.seed
        maxStepsPerEpisode = 200
        earlyStopEnabled = TrainingDefaults.earlyStopEnabled
        earlyStopWindow = TrainingDefaults.earlyStopWindow
        earlyStopRewardThreshold = -110
        clipReward = TrainingDefaults.clipReward
        clipRewardMin = TrainingDefaults.clipRewardMin
        clipRewardMax = TrainingDefaults.clipRewardMax
        targetFPS = TrainingDefaults.targetFPS
        turboMode = TrainingDefaults.turboMode
        goalVelocity = 0.0
        useRewardShaping = true
        velocityShapingCoef = 10.0
        positionShapingCoef = 10.0
        successBonusReward = 100.0
    }
    
    func startTraining() {
        guard !isTraining else { return }
        guard !TrainingState.shared.isTraining else { return }
        
        // If the previous run already completed (or episodesPerRun was lowered),
        // reset the per-run counter so a new run can start.
        if episodesPerRun > 0 && episodesCompletedInRun >= episodesPerRun {
            episodesCompletedInRun = 0
        }

        isTraining = true
        if trainingSessionStartDate == nil {
            trainingSessionStartDate = Date()
        }
        trainingCompletedNormally = false
        hasTrainedSinceLoad = true
        TrainingState.shared.startTraining(environment: Self.displayName)
        
        Task.detached { [weak self] in
            await self?.trainingLoop()
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
    
    func stopRunning() {
        isRunning = false
    }
    
    
    func saveAgent(name: String) throws {
        guard let agent = self.agent else {
            throw AgentStorageError.agentNotFound
        }
        
        let saved = try AgentStorage.shared.saveMountainCarAgent(
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
                "goal_velocity": "\(goalVelocity)"
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
        
        try AgentStorage.shared.updateMountainCarAgent(
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
        guard savedAgent.environmentType == .mountainCar else {
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
        if let gv = savedAgent.environmentConfig["goal_velocity"],
           let gvVal = Double(gv) {
            goalVelocity = gvVal
        }
        
        agent = nil
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
        committedEpisodeMetricsCount = 0
        episodeCount = savedAgent.episodesTrained + 1
        episodesCompletedInRun = 0
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
    }
    
    
    func step(action: Int) {
        guard var env = self.env else { return }
        
        let result = env.step(action)
        self.env = env
        
        currentStep += 1
        episodeReward += result.reward
        totalReward += result.reward
        
        updateSnapshot()
        
        if result.terminated || result.truncated {
            episodeCount += 1
            currentStep = 0
            episodeReward = 0
            _ = env.reset()
            self.env = env
            updateSnapshot()
        }
    }
    
    func runRandomEpisode() {
        guard !isRunning else { return }
        isRunning = true
        
        Task.detached { [weak self] in
            await self?.runRandomEpisodeLoop()
        }
    }
    
    private func runRandomEpisodeLoop() async {
        guard var env = self.env else { return }
        
        _ = env.reset()
        self.env = env
        
        await MainActor.run {
            self.currentStep = 0
            self.episodeReward = 0
            self.updateSnapshot()
        }
        
        var terminated = false
        var truncated = false
        var steps = 0
        
        while !terminated && !truncated && isRunning && steps < maxStepsPerEpisode {
            let action = Int.random(in: 0..<3)
            
            let result = env.step(action)
            self.env = env
            
            terminated = result.terminated
            truncated = result.truncated
            steps += 1
            
            await MainActor.run {
                self.currentStep = steps
                self.episodeReward += result.reward
                self.totalReward += result.reward
                self.updateSnapshot()
            }
            
            if renderEnabled {
                let delayNs = UInt64(1_000_000_000 / self.targetFPS)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }
        
        await MainActor.run {
            self.isRunning = false
            if terminated {
                self.episodeCount += 1
            }
        }
    }
    
    
    private func trainingLoop() async {
        guard var env = self.env else { return }
        
        guard let _ = env.observation_space as? Box,
              let actSpace = env.action_space as? Discrete,
              let dqnAgent = self.agent else {
            await MainActor.run { self.stopTraining() }
            return
        }
        
        // Warmup
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
                
                dqnAgent.store(
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
            
            _ = dqnAgent.update()
            
            env = warmupEnv
            self.env = env
            await MainActor.run { self.isWarmingUp = false }
        }
        
        var lastUIUpdate = Date()
        let uiUpdateInterval: TimeInterval = renderEnabled ? 1.0 / 30.0 : 1.0 / 5.0
        
        while isTraining && episodesCompletedInRun < episodesPerRun {
            let result = env.reset()
            var state = result.obs
            self.env = env
            
            await MainActor.run {
                self.currentStep = 0
                self.episodeReward = 0
                self.updateSnapshot()
            }
            
            var episodeRewardLocal: Double = 0
            var steps = 0
            var terminated = false
            var truncated = false
            var totalLossArray = MLXArray(Float32(0.0))
            var totalMeanQArray = MLXArray(Float32(0.0))
            var totalGradNormArray = MLXArray(Float32(0.0))
            var totalTdErrorArray = MLXArray(Float32(0.0))
            var lossCount = 0
            
            while !terminated && !truncated && isTraining && steps < maxStepsPerEpisode {
                let actionArray = dqnAgent.chooseAction(
                    state: state,
                    actionSpace: actSpace,
                    key: &rngKey
                )
                let action = actionArray[0, 0].item(Int.self)
                
                let stepResult = env.step(action)
                self.env = env
                
                let nextState = stepResult.obs
                let reward = stepResult.reward
                terminated = stepResult.terminated
                truncated = stepResult.truncated
                
                let usedReward = clipReward ? min(max(reward, clipRewardMin), clipRewardMax) : reward
                
                dqnAgent.store(
                    state: state,
                    action: actionArray,
                    reward: Float(usedReward),
                    nextState: nextState,
                    terminated: terminated
                )
                
                state = nextState
                episodeRewardLocal += stepResult.reward
                steps += 1
                totalSteps += 1

                if totalSteps >= warmupSteps {
                    if let (loss, meanQ, gradNorm, tdError) = dqnAgent.updateArrays() {
                        totalLossArray = totalLossArray + loss
                        totalMeanQArray = totalMeanQArray + meanQ
                        totalGradNormArray = totalGradNormArray + gradNorm
                        totalTdErrorArray = totalTdErrorArray + tdError
                        lossCount += 1
                    }
                }
                
                let now = Date()
                if renderEnabled && !turboMode {
                    let currentSteps = steps
                    let currentReward = episodeRewardLocal
                    let currentEpsilon = Double(dqnAgent.epsilon)
                    await MainActor.run {
                        self.currentStep = currentSteps
                        self.episodeReward = currentReward
                        self.epsilon = currentEpsilon
                        self.updateSnapshot()
                    }
                    
                    let delayNs = UInt64(1_000_000_000 / targetFPS)
                    try? await Task.sleep(nanoseconds: delayNs)
                } else if now.timeIntervalSince(lastUIUpdate) >= uiUpdateInterval {
                    let currentSteps = steps
                    let currentReward = episodeRewardLocal
                    let currentEpsilon = Double(dqnAgent.epsilon)
                    await MainActor.run {
                        self.currentStep = currentSteps
                        self.episodeReward = currentReward
                        self.epsilon = currentEpsilon
                    }
                    lastUIUpdate = now
                }
                
                if !renderEnabled && steps % 10 == 0 {
                    await Task.yield()
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
            
            episodesCompletedInRun += 1
            
            let avgLoss: Double? = lossCount > 0 ? Double((totalLossArray / Float(lossCount)).item(Float.self)) : nil
            let avgMaxQ: Double = lossCount > 0 ? Double((totalMeanQArray / Float(lossCount)).item(Float.self)) : 0.0
            let avgGradNorm: Double? = lossCount > 0 ? Double((totalGradNormArray / Float(lossCount)).item(Float.self)) : nil
            let avgTdError: Double = lossCount > 0 ? Double((totalTdErrorArray / Float(lossCount)).item(Float.self)) : 0.0
            let recentRewards = episodeMetrics.suffix(movingAverageWindow).map { $0.reward }
            let movingAvg = recentRewards.isEmpty ? episodeRewardLocal : recentRewards.reduce(0, +) / Double(recentRewards.count)
            
            let completedEpisodeNumber = await MainActor.run { loadedEpisodeCount + uncommittedEpisodeCount + 1 }
            
            let metrics = EpisodeMetrics(
                episode: completedEpisodeNumber,
                reward: episodeRewardLocal,
                steps: steps,
                success: terminated,
                averageTDError: avgTdError,
                averageLoss: avgLoss,
                averageMaxQ: avgMaxQ,
                epsilon: Double(dqnAgent.epsilon),
                alpha: nil,
                averageGradNorm: avgGradNorm,
                rewardMovingAverage: movingAvg
            )
            
            let finalSteps = steps
            let finalReward = episodeRewardLocal
            let finalEpsilon = Double(dqnAgent.epsilon)
            await MainActor.run {
                self.currentStep = finalSteps
                self.episodeReward = finalReward
                self.totalReward += finalReward
                self.epsilon = finalEpsilon
                self.episodeMetrics.append(metrics)
                self.episodeCount += 1
                
                if !self.renderEnabled {
                    self.updateSnapshot()
                }
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
            
            if turboMode {
                await Task.yield()
            }
        }
        
        await MainActor.run {
            if self.isTraining {
                self.trainingCompletedNormally = true
            }
            self.stopTraining()
        }
    }
}

//
//  LunarLanderContinuousRunner.swift
//

import SwiftUI
import Gymnazo
import MLX
import MLXNN

@MainActor
@Observable class LunarLanderContinuousRunner: SavableEnvironmentRunner {
    var snapshot: LunarLanderSnapshot?
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
    private var loadedBestReward: Double = -500
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
        let newBest = episodeMetrics.map { $0.reward }.max() ?? -500
        return max(loadedBestReward, newBest)
    }
    
    static var environmentType: EnvironmentType { .lunarLanderContinuous }
    static var displayName: String { "Lunar Lander Continuous" }
    static var algorithmName: String { "SAC" }
    static var icon: String { "airplane.circle.fill" }
    static var accentColor: Color { .teal }
    static var category: EnvironmentCategory { .box2d }
    
    var isRunning = false
    var totalReward = 0.0
    var turboMode: Bool = TrainingDefaults.turboMode
    var movingAverageWindow = 100
    
    var useSeed: Bool = TrainingDefaults.useSeed
    var seed: Int = TrainingDefaults.seed
    
    var hiddenSize1: Int = LunarLanderContinuousSAC.Defaults.hiddenSize1
    var hiddenSize2: Int = LunarLanderContinuousSAC.Defaults.hiddenSize2
    
    var learningRate: Double = Double(LunarLanderContinuousSAC.Defaults.learningRate)
    var useLinearLrSchedule: Bool = true
    var autoLrScheduleTotalTimesteps: Bool = true
    var lrScheduleTotalTimesteps: Int = 500_000
    
    var effectiveLrScheduleTotalTimesteps: Int {
        if autoLrScheduleTotalTimesteps {
            let planned = Int64(episodesPerRun) * Int64(maxStepsPerEpisode)
            return max(1, Int(min(planned, Int64(Int.max))))
        }
        return max(1, lrScheduleTotalTimesteps)
    }
    var gamma: Double = Double(LunarLanderContinuousSAC.Defaults.gamma)
    var tau: Double = Double(LunarLanderContinuousSAC.Defaults.tau)
    var alpha: Double = 1.0
    var batchSize: Int = LunarLanderContinuousSAC.Defaults.batchSize
    var bufferSize: Int = LunarLanderContinuousSAC.Defaults.bufferSize
    var warmupSteps: Int = 10_000
    var maxStepsPerEpisode: Int = 1000
    
    var autoAlpha: Bool = true
    var initAlpha: Double = 1.0
    var alphaLr: Double = 0.00073
    var trainFreqSteps: Int = 1
    var gradientStepsPerTrain: Int = 1
    
    var envGravity: Double = -10.0
    var enableWind: Bool = false
    var windPower: Double = 15.0
    var turbulencePower: Double = 1.5
    
    private struct AgentInitConfig: Equatable {
        let hiddenSize1: Int
        let hiddenSize2: Int
        let learningRate: Double
        let gamma: Double
        let tau: Double
        let batchSize: Int
        let bufferSize: Int
        let autoAlpha: Bool
        let alpha: Double
        let initAlpha: Double
        let alphaLr: Double
    }
    private var lastAgentInitConfig: AgentInitConfig? = nil
    
    private var episodesCompletedInRun: Int = 0
    private var env: (any Env<MLXArray, MLXArray>)?
    private var rngKey: MLXArray
    private var agent: LunarLanderContinuousSAC?
    private var totalSteps: Int = 0
    
    var isWarmingUp: Bool = false
    var warmupProgress: Double {
        guard warmupSteps > 0 else { return 1.0 }
        return min(1.0, Double(totalSteps) / Double(warmupSteps))
    }
    
    var landingSuccessRate: Double {
        guard !episodeMetrics.isEmpty else { return 0 }
        let recent = episodeMetrics.suffix(movingAverageWindow)
        let successes = recent.filter { $0.reward >= 200 }.count
        return Double(successes) / Double(recent.count)
    }
    
    init() {
        self.rngKey = MLX.key(0)
        setupEnvironment()
    }
    
    func setupEnvironment() {
        var kwargs: [String: Any] = [
            "gravity": envGravity,
            "enable_wind": enableWind,
            "wind_power": windPower,
            "turbulence_power": turbulencePower
        ]
        if renderEnabled {
            kwargs["render_mode"] = "human"
        }
        
        guard var env = Gymnazo.make(
            "LunarLanderContinuous",
            maxEpisodeSteps: maxStepsPerEpisode,
            kwargs: kwargs
        ) as? any Env<MLXArray, MLXArray> else {
            print("Failed to create LunarLanderContinuous environment")
            return
        }
        
        let _ = env.reset()
        
        if renderEnabled {
            self.snapshot = env.render() as? LunarLanderSnapshot
        } else {
            self.snapshot = nil
        }
        
        self.env = env
        
        if useSeed {
            self.rngKey = MLX.key(UInt64(seed))
        } else {
            self.rngKey = MLX.key(0)
        }
        
        let currentCfg = AgentInitConfig(
            hiddenSize1: hiddenSize1,
            hiddenSize2: hiddenSize2,
            learningRate: learningRate,
            gamma: gamma,
            tau: tau,
            batchSize: batchSize,
            bufferSize: bufferSize,
            autoAlpha: autoAlpha,
            alpha: alpha,
            initAlpha: initAlpha,
            alphaLr: alphaLr
        )
        
        if agent == nil || lastAgentInitConfig != currentCfg {
            let entCoefMode: EntropyCoefficientMode
            if autoAlpha {
                entCoefMode = .auto(initAlpha: Float(initAlpha), alphaLr: Float(alphaLr), targetEntropy: nil)
            } else {
                entCoefMode = .fixed(alpha: Float(alpha))
            }
            
            agent = LunarLanderContinuousSAC(
                hiddenSize1: hiddenSize1,
                hiddenSize2: hiddenSize2,
                learningRate: Float(learningRate),
                gamma: Float(gamma),
                tau: Float(tau),
                batchSize: batchSize,
                bufferSize: bufferSize,
                entCoefMode: entCoefMode
            )
            lastAgentInitConfig = currentCfg
        }
        
        if let agent = agent {
            if useLinearLrSchedule {
                agent.setLearningRateSchedule(.linearDecay)
            } else {
                agent.setLearningRateSchedule(.constant)
            }
            let total = Double(effectiveLrScheduleTotalTimesteps)
            let progress = max(0.0, 1.0 - Double(totalSteps) / total)
            agent.setProgressRemaining(Float(progress))
        }
        
        episodeMetrics.removeAll()
        committedEpisodeMetricsCount = 0
        episodeCount = 1
        currentStep = 0
        totalReward = 0
        episodeReward = 0
        totalSteps = 0
        episodesCompletedInRun = 0
    }
    
    private func updateSnapshot() {
        if renderEnabled {
            self.snapshot = self.env?.render() as? LunarLanderSnapshot
        }
    }
    
    func reset() {
        stopTraining()
        stopRunning()
        accumulatedTrainingTimeSeconds = 0
        trainingSessionStartDate = nil
        agent = nil
        alpha = 1.0
        autoAlpha = true
        initAlpha = 1.0
        alphaLr = 0.00073
        trainFreqSteps = 1
        gradientStepsPerTrain = 1
        loadedAgentId = nil
        loadedAgentName = nil
        hasTrainedSinceLoad = false
        loadedEpisodeCount = 0
        loadedBestReward = -500
        trainingCompletedNormally = false
        committedEpisodeMetricsCount = 0
        setupEnvironment()
    }
    
    func resetToDefaults() {
        hiddenSize1 = LunarLanderContinuousSAC.Defaults.hiddenSize1
        hiddenSize2 = LunarLanderContinuousSAC.Defaults.hiddenSize2
        learningRate = Double(LunarLanderContinuousSAC.Defaults.learningRate)
        useLinearLrSchedule = true
        autoLrScheduleTotalTimesteps = false
        lrScheduleTotalTimesteps = 500_000
        gamma = Double(LunarLanderContinuousSAC.Defaults.gamma)
        tau = Double(LunarLanderContinuousSAC.Defaults.tau)
        alpha = 1.0
        autoAlpha = true
        initAlpha = 1.0
        alphaLr = 0.00073
        trainFreqSteps = 1
        gradientStepsPerTrain = 1
        batchSize = LunarLanderContinuousSAC.Defaults.batchSize
        bufferSize = LunarLanderContinuousSAC.Defaults.bufferSize
        
        warmupSteps = 10_000
        renderEnabled = TrainingDefaults.renderEnabled
        episodesPerRun = TrainingDefaults.episodesPerRun
        episodesCompletedInRun = 0
        useSeed = TrainingDefaults.useSeed
        seed = TrainingDefaults.seed
        maxStepsPerEpisode = 1000
        targetFPS = TrainingDefaults.targetFPS
        turboMode = TrainingDefaults.turboMode
        envGravity = -10.0
        enableWind = false
        windPower = 15.0
        turbulencePower = 1.5
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
        
        let saved = try AgentStorage.shared.saveLunarLanderContinuousAgent(
            name: name,
            actor: agent.actor,
            qEnsemble: agent.qEnsemble,
            logAlphaValue: agent.logAlphaModule.value,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            alpha: alpha,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "hiddenSize1": Double(hiddenSize1),
                "hiddenSize2": Double(hiddenSize2),
                "learningRate": learningRate,
                "useLinearLrSchedule": useLinearLrSchedule ? 1.0 : 0.0,
                "autoLrScheduleTotalTimesteps": autoLrScheduleTotalTimesteps ? 1.0 : 0.0,
                "lrScheduleTotalTimesteps": Double(lrScheduleTotalTimesteps),
                "gamma": gamma,
                "tau": tau,
                "alpha": alpha,
                "autoAlpha": autoAlpha ? 1.0 : 0.0,
                "initAlpha": initAlpha,
                "alphaLr": alphaLr,
                "trainFreqSteps": Double(trainFreqSteps),
                "gradientStepsPerTrain": Double(gradientStepsPerTrain),
                "batchSize": Double(batchSize),
                "bufferSize": Double(bufferSize),
                "warmupSteps": Double(warmupSteps),
                "totalSteps": Double(totalSteps)
            ],
            environmentConfig: [
                "maxStepsPerEpisode": "\(maxStepsPerEpisode)",
                "gravity": "\(envGravity)",
                "enable_wind": enableWind ? "true" : "false",
                "wind_power": "\(windPower)",
                "turbulence_power": "\(turbulencePower)"
            ],
            hiddenSizes: [hiddenSize1, hiddenSize2]
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
        
        try AgentStorage.shared.updateLunarLanderContinuousAgent(
            id: id,
            newName: name,
            actor: agent.actor,
            qEnsemble: agent.qEnsemble,
            logAlphaValue: agent.logAlphaModule.value,
            episodesTrained: totalEpisodesTrained,
            trainingTimeSeconds: totalTrainingTimeSeconds,
            alpha: alpha,
            bestReward: combinedBestReward,
            averageReward: averageReward,
            hyperparameters: [
                "hiddenSize1": Double(hiddenSize1),
                "hiddenSize2": Double(hiddenSize2),
                "learningRate": learningRate,
                "useLinearLrSchedule": useLinearLrSchedule ? 1.0 : 0.0,
                "autoLrScheduleTotalTimesteps": autoLrScheduleTotalTimesteps ? 1.0 : 0.0,
                "lrScheduleTotalTimesteps": Double(lrScheduleTotalTimesteps),
                "gamma": gamma,
                "tau": tau,
                "alpha": alpha,
                "autoAlpha": autoAlpha ? 1.0 : 0.0,
                "initAlpha": initAlpha,
                "alphaLr": alphaLr,
                "trainFreqSteps": Double(trainFreqSteps),
                "gradientStepsPerTrain": Double(gradientStepsPerTrain),
                "batchSize": Double(batchSize),
                "bufferSize": Double(bufferSize),
                "warmupSteps": Double(warmupSteps),
                "totalSteps": Double(totalSteps)
            ]
        )
        
        loadedAgentName = name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = totalEpisodesTrained
        committedEpisodeMetricsCount = episodeMetrics.count
        accumulatedTrainingTimeSeconds = totalTrainingTimeSeconds
    }
    
    func loadAgent(from savedAgent: SavedAgent) throws {
        guard savedAgent.environmentType == .lunarLanderContinuous else {
            throw AgentStorageError.wrongEnvironmentType
        }
        
        stopTraining()
        accumulatedTrainingTimeSeconds = savedAgent.trainingTimeSeconds ?? 0
        trainingSessionStartDate = nil
        
        if let h1 = savedAgent.hyperparameters["hiddenSize1"] { hiddenSize1 = Int(h1.rounded()) }
        if let h2 = savedAgent.hyperparameters["hiddenSize2"] { hiddenSize2 = Int(h2.rounded()) }
        else if let actorArch = savedAgent.networkArchitecture?.first(where: { $0.networkType == "actor" }),
                actorArch.hiddenSizes.count >= 2 {
            hiddenSize1 = actorArch.hiddenSizes[0]
            hiddenSize2 = actorArch.hiddenSizes[1]
        }
        
        if let lr = savedAgent.hyperparameters["learningRate"] { learningRate = lr }
        if let sched = savedAgent.hyperparameters["useLinearLrSchedule"] { useLinearLrSchedule = sched > 0.5 }
        if let auto = savedAgent.hyperparameters["autoLrScheduleTotalTimesteps"] { autoLrScheduleTotalTimesteps = auto > 0.5 }
        if let total = savedAgent.hyperparameters["lrScheduleTotalTimesteps"] { lrScheduleTotalTimesteps = max(1, Int(total.rounded())) }
        if let g = savedAgent.hyperparameters["gamma"] { gamma = g }
        if let t = savedAgent.hyperparameters["tau"] { tau = t }
        if let a = savedAgent.hyperparameters["alpha"] { alpha = a }
        if let aa = savedAgent.hyperparameters["autoAlpha"] { autoAlpha = aa > 0.5 }
        if let ia = savedAgent.hyperparameters["initAlpha"] { initAlpha = ia }
        if let alr = savedAgent.hyperparameters["alphaLr"] { alphaLr = alr }
        if let tf = savedAgent.hyperparameters["trainFreqSteps"] { trainFreqSteps = max(1, Int(tf)) }
        if let gs = savedAgent.hyperparameters["gradientStepsPerTrain"] { gradientStepsPerTrain = max(1, Int(gs)) }
        if let bs = savedAgent.hyperparameters["batchSize"] { batchSize = Int(bs) }
        if let buf = savedAgent.hyperparameters["bufferSize"] { bufferSize = Int(buf) }
        if let wSteps = savedAgent.hyperparameters["warmupSteps"] { warmupSteps = Int(wSteps) }
        if let tSteps = savedAgent.hyperparameters["totalSteps"] { totalSteps = Int(tSteps) }
        
        if let maxSteps = savedAgent.environmentConfig["maxStepsPerEpisode"],
           let steps = Int(maxSteps) {
            maxStepsPerEpisode = steps
        }
        if let grav = savedAgent.environmentConfig["gravity"],
           let gravVal = Double(grav) {
            envGravity = gravVal
        }
        if let wind = savedAgent.environmentConfig["enable_wind"] {
            enableWind = wind == "true"
        }
        if let wp = savedAgent.environmentConfig["wind_power"],
           let wpVal = Double(wp) {
            windPower = wpVal
        }
        if let tp = savedAgent.environmentConfig["turbulence_power"],
           let tpVal = Double(tp) {
            turbulencePower = tpVal
        }
        
        agent = nil
        setupEnvironment()
        
        let weightsDict = try AgentStorage.shared.loadLunarLanderContinuousWeights(for: savedAgent)
        
        guard let agent = self.agent else {
            throw AgentStorageError.dataCorrupted
        }
        
        let excludedActorKeys = Set([
            "actionScale", "actionBias", "epsilon", "logPiConstant",
            "logStdMinArray", "logStdRangeHalf"
        ])
        
        if let actorWeights = weightsDict["actor"] {
            let filteredWeights = actorWeights.filter { !excludedActorKeys.contains($0.key) }
            let actorTuples = filteredWeights.map { ($0.key, $0.value) }
            let actorParams = NestedDictionary<String, MLXArray>.unflattened(actorTuples)
            agent.actor.update(parameters: actorParams)
        }
        
        if let qEnsembleWeights = weightsDict["qEnsemble"] {
            let qTuples = qEnsembleWeights.map { ($0.key, $0.value) }
            let qParams = NestedDictionary<String, MLXArray>.unflattened(qTuples)
            agent.qEnsemble.update(parameters: qParams)
            agent.qEnsembleTarget.update(parameters: qParams)
        }
        
        if let entCoefWeights = weightsDict["entCoef"], let logAlpha = entCoefWeights["logAlpha"] {
            agent.logAlphaModule.value = logAlpha
            _ = agent.syncAlpha()
            self.alpha = Double(agent.alpha)
        }
        
        eval(agent.actor, agent.qEnsemble, agent.qEnsembleTarget, agent.logAlphaModule)
        
        episodeMetrics = []
        committedEpisodeMetricsCount = 0
        episodeCount = savedAgent.episodesTrained + 1
        
        loadedAgentId = savedAgent.id
        loadedAgentName = savedAgent.name
        hasTrainedSinceLoad = false
        loadedEpisodeCount = savedAgent.episodesTrained
        loadedBestReward = savedAgent.bestReward
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
            let (newKey, actionKey) = MLX.split(key: rngKey)
            rngKey = newKey
            let range: Range<Float> = (-1.0 as Float)..<(1.0 as Float)
            let actionArray = MLX.uniform(range, [2], key: actionKey)
            
            let result = env.step(actionArray)
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
              let _ = env.action_space as? Box,
              let sacAgent = self.agent else {
            await MainActor.run { self.stopTraining() }
            return
        }
        
        if totalSteps < warmupSteps {
            await MainActor.run { self.isWarmingUp = true }
            
            var warmupEnv = env
            let warmupResult = warmupEnv.reset()
            var warmupState = warmupResult.obs
            
            let samplesToCollect = warmupSteps - totalSteps
            
            for i in 0..<samplesToCollect {
                let (newKey, actionKey) = MLX.split(key: rngKey)
                rngKey = newKey
                let range: Range<Float> = LunarLanderContinuousSAC.actionLow..<LunarLanderContinuousSAC.actionHigh
                let action = MLX.uniform(range, [LunarLanderContinuousSAC.actionCount], key: actionKey)
                let stepResult = warmupEnv.step(action)
                
                sacAgent.store(
                    state: warmupState,
                    action: action,
                    reward: Float(stepResult.reward),
                    nextState: stepResult.obs,
                    terminated: stepResult.terminated
                )
                
                warmupState = stepResult.obs
                totalSteps += 1
                
                if useLinearLrSchedule, let agent = self.agent {
                    let total = Double(effectiveLrScheduleTotalTimesteps)
                    let progress = max(0.0, 1.0 - Double(totalSteps) / total)
                    agent.setProgressRemaining(Float(progress))
                }
                
                if stepResult.terminated || stepResult.truncated {
                    let resetResult = warmupEnv.reset()
                    warmupState = resetResult.obs
                }
                
                if i % 100 == 0 {
                    await Task.yield()
                }
            }
            
            sacAgent.updateNoSync()
            
            env = warmupEnv
            await MainActor.run { self.isWarmingUp = false }
            self.env = env
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
            
            while !terminated && !truncated && isTraining && steps < maxStepsPerEpisode {
                let action = sacAgent.chooseAction(state: state, key: &rngKey, deterministic: false)
                
                let stepResult = env.step(action)
                self.env = env
                
                let nextState = stepResult.obs
                let reward = Float(stepResult.reward)
                terminated = stepResult.terminated
                truncated = stepResult.truncated
                
                sacAgent.store(
                    state: state,
                    action: action,
                    reward: reward,
                    nextState: nextState,
                    terminated: terminated
                )
                
                state = nextState
                episodeRewardLocal += stepResult.reward
                steps += 1
                totalSteps += 1
                
                if useLinearLrSchedule {
                    let total = Double(effectiveLrScheduleTotalTimesteps)
                    let progress = max(0.0, 1.0 - Double(totalSteps) / total)
                    sacAgent.setProgressRemaining(Float(progress))
                }

                if totalSteps >= warmupSteps && totalSteps % trainFreqSteps == 0 {
                    for _ in 0..<gradientStepsPerTrain {
                        sacAgent.updateNoSync()
                    }
                }

                if !turboMode {
                    if renderEnabled {
                        let currentSteps = steps
                        let currentReward = episodeRewardLocal
                        await MainActor.run {
                            self.currentStep = currentSteps
                            self.episodeReward = currentReward
                            self.updateSnapshot()
                        }
                        
                        let delayNs = UInt64(1_000_000_000 / targetFPS)
                        try? await Task.sleep(nanoseconds: delayNs)
                    } else {
                        let now = Date()
                        if now.timeIntervalSince(lastUIUpdate) >= uiUpdateInterval {
                            let currentSteps = steps
                            let currentReward = episodeRewardLocal
                            await MainActor.run {
                                self.currentStep = currentSteps
                                self.episodeReward = currentReward
                            }
                            lastUIUpdate = now
                        }
                    }
                } else if steps % 200 == 0 {
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
            
            let recentRewards = episodeMetrics.suffix(movingAverageWindow).map { $0.reward }
            let movingAvg = recentRewards.isEmpty ? episodeRewardLocal : recentRewards.reduce(0, +) / Double(recentRewards.count)
            
            let finalSteps = steps
            let finalReward = episodeRewardLocal
            let finalAlpha = Double(sacAgent.syncAlpha())
            
            await MainActor.run {
                let completedEpisodeNumber = self.loadedEpisodeCount + self.uncommittedEpisodeCount + 1
                
                let metrics = EpisodeMetrics(
                    episode: completedEpisodeNumber,
                    reward: episodeRewardLocal,
                    steps: finalSteps,
                    success: episodeRewardLocal >= 200,
                    averageTDError: 0,
                    averageLoss: nil,
                    averageMaxQ: 0,
                    epsilon: 0,
                    alpha: finalAlpha,
                    averageGradNorm: nil,
                    rewardMovingAverage: movingAvg
                )
                
                self.episodesCompletedInRun += 1
                self.currentStep = finalSteps
                self.episodeReward = finalReward
                self.totalReward += finalReward
                self.alpha = finalAlpha
                self.episodeMetrics.append(metrics)
                self.episodeCount += 1
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

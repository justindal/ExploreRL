//
//  SACCore.swift
//
//  Soft Actor-Critic for continuous action spaces
//  Base class provides algorithm logic - subclasses provide network architecture
//  Based on: https://github.com/vwxyzjn/cleanrl/blob/master/cleanrl/sac_continuous_action.py
//

import Collections
import Foundation
import MLX
import MLXNN
import MLXOptimizers
import Gymnazo
import RealModule


nonisolated public class TrainableParameter: Module {
    var value: MLXArray
    
    public init(_ initialValue: MLXArray) {
        self.value = initialValue
        super.init()
    }
    
    public init(_ initialValue: Float) {
        self.value = MLXArray(initialValue)
        super.init()
    }
    
    public var item: Float {
        value.item(Float.self)
    }
}

/// Protocol for SAC actor networks
public protocol SACActorProtocol: Module {
    nonisolated var actionScale: MLXArray { get }
    nonisolated var actionBias: MLXArray { get }
    
    func callAsFunction(_ x: MLXArray) -> (mean: MLXArray, logStd: MLXArray)
    func sample(obs: MLXArray, key: MLXArray) -> (action: MLXArray, logProb: MLXArray, mean: MLXArray)
    func getDeterministicAction(obs: MLXArray) -> MLXArray
}

/// Protocol for SAC critic networks (single Q-network)
public protocol SACCriticProtocol: Module {
    func callAsFunction(obs: MLXArray, action: MLXArray) -> MLXArray
}

/// Protocol for ensemble Q-networks
public protocol SACEnsembleCriticProtocol: Module {
    func callAsFunction(obs: MLXArray, action: MLXArray) -> MLXArray
    func minQ(obs: MLXArray, action: MLXArray) -> MLXArray
}

public struct SACExperience {
    public let observation: MLXArray
    public let nextObservation: MLXArray
    public let action: MLXArray
    public let reward: MLXArray
    public let terminated: MLXArray
}

public class SACReplayBuffer {
    public let capacity: Int
    public let stateSize: Int
    public let actionSize: Int
    
    var obsBuffer: [Float]
    var nextObsBuffer: [Float]
    var actionBuffer: [Float]
    var rewardBuffer: [Float]
    var terminatedBuffer: [Float]
    
    var ptr: Int = 0
    var size: Int = 0
    
    public init(capacity: Int, stateSize: Int, actionSize: Int) {
        self.capacity = capacity
        self.stateSize = stateSize
        self.actionSize = actionSize
        
        self.obsBuffer = [Float](repeating: 0, count: capacity * stateSize)
        self.nextObsBuffer = [Float](repeating: 0, count: capacity * stateSize)
        self.actionBuffer = [Float](repeating: 0, count: capacity * actionSize)
        self.rewardBuffer = [Float](repeating: 0, count: capacity)
        self.terminatedBuffer = [Float](repeating: 0, count: capacity)
    }
    
    public func push(_ experience: SACExperience) {
        let obsFlat = experience.observation.asArray(Float.self)
        let nextObsFlat = experience.nextObservation.asArray(Float.self)
        let actionFlat = experience.action.asArray(Float.self)
        let rewardScalar = experience.reward.item(Float.self)
        let termScalar = experience.terminated.item(Float.self)
        
        let obsStart = ptr * stateSize
        let actionStart = ptr * actionSize
        
        for i in 0..<stateSize {
            obsBuffer[obsStart + i] = obsFlat[i]
            nextObsBuffer[obsStart + i] = nextObsFlat[i]
        }
        
        for i in 0..<actionSize {
            actionBuffer[actionStart + i] = actionFlat[i]
        }
        
        rewardBuffer[ptr] = rewardScalar
        terminatedBuffer[ptr] = termScalar
        
        ptr = (ptr + 1) % capacity
        size = min(size + 1, capacity)
    }
    
    public func sample(batchSize: Int) -> (MLXArray, MLXArray, MLXArray, MLXArray, MLXArray) {
        let safeBatchSize = min(batchSize, size)
        
        var indices = [Int]()
        indices.reserveCapacity(safeBatchSize)
        for _ in 0..<safeBatchSize {
            indices.append(Int.random(in: 0..<size))
        }
        
        var bObs = [Float]()
        var bNextObs = [Float]()
        var bActions = [Float]()
        var bRewards = [Float]()
        var bTerminated = [Float]()
        
        bObs.reserveCapacity(safeBatchSize * stateSize)
        bNextObs.reserveCapacity(safeBatchSize * stateSize)
        bActions.reserveCapacity(safeBatchSize * actionSize)
        bRewards.reserveCapacity(safeBatchSize)
        bTerminated.reserveCapacity(safeBatchSize)
        
        for idx in indices {
            let obsStart = idx * stateSize
            let actionStart = idx * actionSize
            
            bObs.append(contentsOf: obsBuffer[obsStart..<(obsStart + stateSize)])
            bNextObs.append(contentsOf: nextObsBuffer[obsStart..<(obsStart + stateSize)])
            bActions.append(contentsOf: actionBuffer[actionStart..<(actionStart + actionSize)])
            bRewards.append(rewardBuffer[idx])
            bTerminated.append(terminatedBuffer[idx])
        }
        
        let mlxObs = MLXArray(bObs).reshaped([safeBatchSize, stateSize])
        let mlxNextObs = MLXArray(bNextObs).reshaped([safeBatchSize, stateSize])
        let mlxActions = MLXArray(bActions).reshaped([safeBatchSize, actionSize])
        let mlxRewards = MLXArray(bRewards).reshaped([safeBatchSize, 1])
        let mlxTerminated = MLXArray(bTerminated).reshaped([safeBatchSize, 1])
        
        return (mlxObs, mlxNextObs, mlxActions, mlxRewards, mlxTerminated)
    }
    
    public var count: Int { size }
}

/// Base SAC agent class using twin Q-networks.
public class SACAgent<Actor: SACActorProtocol, Critic: SACCriticProtocol>: ContinuousDeepRLAgent {
    public let actor: Actor
    public let qf1: Critic
    public let qf2: Critic
    public let qf1Target: Critic
    public let qf2Target: Critic
    
    public let actorOptimizer: Adam
    public let qOptimizer: Adam
    
    public let memory: SACReplayBuffer
    
    public let stateSize: Int
    public let actionSize: Int
    public let gamma: Float
    public let tau: Float
    public let batchSize: Int
    public var alpha: Float
    public var targetEntropy: Float
    public var targetEntropyArray: MLXArray
    public let logAlphaModule: TrainableParameter
    
    public let minLogAlpha: Float
    public let maxLogAlpha: Float
    private let minLogAlphaArray: MLXArray
    private let maxLogAlphaArray: MLXArray
    private let alphaLearningRate: MLXArray
    
    public var steps: Int = 0
    
    public func syncAlpha() -> Float {
        let alphaArray = exp(logAlphaModule.value)
        eval(alphaArray)
        let v = alphaArray.item(Float.self)
        alpha = v
        return v
    }
    
    public init(
        actor: Actor,
        qf1: Critic,
        qf2: Critic,
        qf1Target: Critic,
        qf2Target: Critic,
        stateSize: Int,
        actionSize: Int,
        learningRate: Float,
        gamma: Float,
        tau: Float,
        alpha: Float,
        batchSize: Int,
        bufferSize: Int,
        minLogAlpha: Float = -5.0,
        maxLogAlpha: Float = 2.0
    ) {
        self.actor = actor
        self.qf1 = qf1
        self.qf2 = qf2
        self.qf1Target = qf1Target
        self.qf2Target = qf2Target
        
        self.stateSize = stateSize
        self.actionSize = actionSize
        
        self.qf1Target.update(parameters: qf1.parameters())
        self.qf2Target.update(parameters: qf2.parameters())
        
        self.actorOptimizer = Adam(learningRate: learningRate)
        self.qOptimizer = Adam(learningRate: learningRate)
        
        self.memory = SACReplayBuffer(capacity: bufferSize, stateSize: stateSize, actionSize: actionSize)
        
        self.gamma = gamma
        self.tau = tau
        self.batchSize = batchSize
        self.alpha = alpha
        
        self.minLogAlpha = minLogAlpha
        self.maxLogAlpha = maxLogAlpha
        self.minLogAlphaArray = MLXArray(minLogAlpha)
        self.maxLogAlphaArray = MLXArray(maxLogAlpha)
        
        self.targetEntropy = -Float(actionSize)
        self.targetEntropyArray = MLXArray(-Float(actionSize))
        self.logAlphaModule = TrainableParameter(log(alpha))
        self.alphaLearningRate = MLXArray(learningRate)
        
        eval(actor, qf1, qf2, qf1Target, qf2Target, logAlphaModule)
    }
    
    public func chooseAction(state: MLXArray, key: inout MLXArray, deterministic: Bool = false) -> MLXArray {
        let stateRow = state.count == stateSize ? state.reshaped([1, stateSize]) : state
        
        if deterministic {
            return actor.getDeterministicAction(obs: stateRow).reshaped([actionSize])
        }
        
        let (k1, k2) = MLX.split(key: key)
        key = k2
        let (action, _, _) = actor.sample(obs: stateRow, key: k1)
        return action.reshaped([actionSize])
    }
    
    public func store(state: MLXArray, action: MLXArray, reward: Float, nextState: MLXArray, terminated: Bool) {
        let exp = SACExperience(
            observation: state,
            nextObservation: nextState,
            action: action,
            reward: MLXArray(Float32(reward)),
            terminated: MLXArray(Float32(terminated ? 1.0 : 0.0))
        )
        memory.push(exp)
    }
    
    private func updateQ(
        batchObs: MLXArray,
        batchNextObs: MLXArray,
        batchActions: MLXArray,
        batchRewards: MLXArray,
        batchTerminated: MLXArray,
        rngKey: MLXArray,
        alphaVal: MLXArray
    ) -> MLXArray {
        let gammaArr = MLXArray(gamma)
        
        let (nextActions, nextLogProbs, _) = actor.sample(obs: batchNextObs, key: rngKey)
        let qf1NextTarget = qf1Target.callAsFunction(obs: batchNextObs, action: nextActions)
        let qf2NextTarget = qf2Target.callAsFunction(obs: batchNextObs, action: nextActions)
        let minQfNextTarget = minimum(qf1NextTarget, qf2NextTarget) - alphaVal * nextLogProbs
        let nextQValue = stopGradient(batchRewards + (1.0 - batchTerminated) * gammaArr * minQfNextTarget)
        
        let qf1LossAndGrad = valueAndGrad(model: qf1) { (model: Critic, obs: MLXArray, targets: MLXArray) -> MLXArray in
            let qVal = model.callAsFunction(obs: obs, action: batchActions)
            return pow(qVal - targets, 2.0).mean()
        }
        let (qf1LossValue, qf1Grads) = qf1LossAndGrad(qf1, batchObs, nextQValue)
        qOptimizer.update(model: qf1, gradients: qf1Grads)
        
        let qf2LossAndGrad = valueAndGrad(model: qf2) { (model: Critic, obs: MLXArray, targets: MLXArray) -> MLXArray in
            let qVal = model.callAsFunction(obs: obs, action: batchActions)
            return pow(qVal - targets, 2.0).mean()
        }
        let (qf2LossValue, qf2Grads) = qf2LossAndGrad(qf2, batchObs, nextQValue)
        qOptimizer.update(model: qf2, gradients: qf2Grads)
        
        return qf1LossValue + qf2LossValue
    }
    
    private func updateActor(
        batchObs: MLXArray,
        rngKey: MLXArray,
        alphaVal: MLXArray
    ) -> (actorLoss: MLXArray, meanLogPi: MLXArray) {
        let (_, logPiForAlpha, _) = actor.sample(obs: batchObs, key: rngKey)
        let meanLogPi = logPiForAlpha.mean()
        
        let actorLossAndGrad = valueAndGrad(model: actor) { [self] (model: Actor, obs: MLXArray, key: MLXArray) -> MLXArray in
            let (piAct, logP, _) = model.sample(obs: obs, key: key)
            let q1Pi = qf1.callAsFunction(obs: obs, action: piAct)
            let q2Pi = qf2.callAsFunction(obs: obs, action: piAct)
            let minQ = minimum(q1Pi, q2Pi)
            return (alphaVal * logP - minQ).mean()
        }
        
        let (actorLossValue, actorGrads) = actorLossAndGrad(actor, batchObs, rngKey)
        actorOptimizer.update(model: actor, gradients: actorGrads)
        
        return (actorLossValue, meanLogPi)
    }
    
    private func updateInternal(syncScalars: Bool) -> (qLoss: Float, actorLoss: Float, alphaLoss: Float)? {
        guard memory.count >= batchSize else { return nil }
        
        steps += 1
        
        let (batchObs, batchNextObs, batchActions, batchRewards, batchTerminated) = memory.sample(batchSize: batchSize)
        
        let batchRewardsFloat = batchRewards.asType(.float32)
        let batchTerminatedFloat = batchTerminated.asType(.float32)
        
        let key = MLX.key(UInt64(steps))
        let (k1, k2) = MLX.split(key: key)
        
        let alphaVal = exp(logAlphaModule.value)
        
        let totalQLoss = updateQ(
            batchObs: batchObs,
            batchNextObs: batchNextObs,
            batchActions: batchActions,
            batchRewards: batchRewardsFloat,
            batchTerminated: batchTerminatedFloat,
            rngKey: k1,
            alphaVal: alphaVal
        )
        
        let (actorLossValue, meanLogPi) = updateActor(
            batchObs: batchObs,
            rngKey: k2,
            alphaVal: alphaVal
        )
        
        softUpdateTargetNetworks()
        
        let currentAlpha = exp(logAlphaModule.value)
        let entropyDiff = (stopGradient(meanLogPi) - targetEntropyArray).mean()
        let alphaLossArray = -currentAlpha * entropyDiff
        logAlphaModule.value = logAlphaModule.value + alphaLearningRate * currentAlpha * entropyDiff
        logAlphaModule.value = minimum(maximum(logAlphaModule.value, minLogAlphaArray), maxLogAlphaArray)
        
        eval(totalQLoss, actorLossValue, alphaLossArray, actor, qf1, qf2, qf1Target, qf2Target, logAlphaModule)
        
        if syncScalars {
            _ = syncAlpha()
            
            return (totalQLoss.item(Float.self), actorLossValue.item(Float.self), alphaLossArray.item(Float.self))
        } else {
            return nil
        }
    }
    
    public func updateNoSync() {
        _ = updateInternal(syncScalars: false)
    }
    
    public func update() -> (qLoss: Float, actorLoss: Float, alphaLoss: Float)? {
        updateInternal(syncScalars: true)
    }
    
    private func softUpdateTargetNetworks() {
        softUpdate(target: qf1Target, source: qf1, tau: tau)
        softUpdate(target: qf2Target, source: qf2, tau: tau)
    }
}

/// SAC agent using vmap'd ensemble Q-networks.
public class SACAgentVmap<Actor: SACActorProtocol, Ensemble: SACEnsembleCriticProtocol>: ContinuousDeepRLAgent {
    public let actor: Actor
    public let qEnsemble: Ensemble
    public let qEnsembleTarget: Ensemble
    
    public let actorOptimizer: Adam
    public let qOptimizer: Adam
    
    public let memory: SACReplayBuffer
    
    public let stateSize: Int
    public let actionSize: Int
    public let gamma: Float
    public let tau: Float
    public let batchSize: Int
    public var alpha: Float
    public var targetEntropy: Float
    public var targetEntropyArray: MLXArray
    public let logAlphaModule: TrainableParameter
    
    public let minLogAlpha: Float
    public let maxLogAlpha: Float
    private let minLogAlphaArray: MLXArray
    private let maxLogAlphaArray: MLXArray
    private let alphaLearningRate: MLXArray
    
    public var steps: Int = 0
    
    private let gammaArray: MLXArray
    
    public func syncAlpha() -> Float {
        let alphaArray = exp(logAlphaModule.value)
        eval(alphaArray)
        let v = alphaArray.item(Float.self)
        alpha = v
        return v
    }
    
    public init(
        actor: Actor,
        qEnsemble: Ensemble,
        qEnsembleTarget: Ensemble,
        stateSize: Int,
        actionSize: Int,
        learningRate: Float,
        gamma: Float,
        tau: Float,
        alpha: Float,
        batchSize: Int,
        bufferSize: Int,
        minLogAlpha: Float = -5.0,
        maxLogAlpha: Float = 2.0
    ) {
        self.actor = actor
        self.qEnsemble = qEnsemble
        self.qEnsembleTarget = qEnsembleTarget
        
        self.stateSize = stateSize
        self.actionSize = actionSize
        
        self.qEnsembleTarget.update(parameters: qEnsemble.parameters())
        
        self.actorOptimizer = Adam(learningRate: learningRate)
        self.qOptimizer = Adam(learningRate: learningRate)
        
        self.memory = SACReplayBuffer(capacity: bufferSize, stateSize: stateSize, actionSize: actionSize)
        
        self.gamma = gamma
        self.tau = tau
        self.batchSize = batchSize
        self.alpha = alpha
        
        self.minLogAlpha = minLogAlpha
        self.maxLogAlpha = maxLogAlpha
        self.minLogAlphaArray = MLXArray(minLogAlpha)
        self.maxLogAlphaArray = MLXArray(maxLogAlpha)
        
        self.targetEntropy = -Float(actionSize)
        self.targetEntropyArray = MLXArray(-Float(actionSize))
        self.logAlphaModule = TrainableParameter(log(alpha))
        self.alphaLearningRate = MLXArray(learningRate)
        
        self.gammaArray = MLXArray(gamma)
        
        eval(actor, qEnsemble, qEnsembleTarget, logAlphaModule)
    }
    
    public func chooseAction(state: MLXArray, key: inout MLXArray, deterministic: Bool = false) -> MLXArray {
        let stateRow = state.count == stateSize ? state.reshaped([1, stateSize]) : state
        
        if deterministic {
            return actor.getDeterministicAction(obs: stateRow).reshaped([actionSize])
        }
        
        let (k1, k2) = MLX.split(key: key)
        key = k2
        let (action, _, _) = actor.sample(obs: stateRow, key: k1)
        return action.reshaped([actionSize])
    }
    
    public func store(state: MLXArray, action: MLXArray, reward: Float, nextState: MLXArray, terminated: Bool) {
        let exp = SACExperience(
            observation: state,
            nextObservation: nextState,
            action: action,
            reward: MLXArray(Float32(reward)),
            terminated: MLXArray(Float32(terminated ? 1.0 : 0.0))
        )
        memory.push(exp)
    }
    
    private func updateQ(
        batchObs: MLXArray,
        batchNextObs: MLXArray,
        batchActions: MLXArray,
        batchRewards: MLXArray,
        batchTerminated: MLXArray,
        rngKey: MLXArray,
        alphaVal: MLXArray
    ) -> MLXArray {
        let (nextActions, nextLogProbs, _) = actor.sample(obs: batchNextObs, key: rngKey)
        
        let minQfNextTarget = qEnsembleTarget.minQ(obs: batchNextObs, action: nextActions)
        let targetWithEntropy = minQfNextTarget - alphaVal * nextLogProbs
        let nextQValue = stopGradient(batchRewards + (1.0 - batchTerminated) * gammaArray * targetWithEntropy)
        
        let qLossAndGrad = valueAndGrad(model: qEnsemble) { (model: Ensemble, obs: MLXArray, targets: MLXArray) -> MLXArray in
            let allQ = model.callAsFunction(obs: obs, action: batchActions)
            let q1 = allQ[0]
            let q2 = allQ[1]
            let loss1 = pow(q1 - targets, 2.0).mean()
            let loss2 = pow(q2 - targets, 2.0).mean()
            return loss1 + loss2
        }
        
        let (totalQLoss, qGrads) = qLossAndGrad(qEnsemble, batchObs, nextQValue)
        qOptimizer.update(model: qEnsemble, gradients: qGrads)
        
        return totalQLoss
    }
    
    private func updateActor(
        batchObs: MLXArray,
        rngKey: MLXArray,
        alphaVal: MLXArray
    ) -> (actorLoss: MLXArray, meanLogPi: MLXArray) {
        let (_, logPiForAlpha, _) = actor.sample(obs: batchObs, key: rngKey)
        let meanLogPi = logPiForAlpha.mean()
        
        let actorLossAndGrad = valueAndGrad(model: actor) { [self] (model: Actor, obs: MLXArray, key: MLXArray) -> MLXArray in
            let (piAct, logP, _) = model.sample(obs: obs, key: key)
            let minQ = qEnsemble.minQ(obs: obs, action: piAct)
            return (alphaVal * logP - minQ).mean()
        }
        
        let (actorLossValue, actorGrads) = actorLossAndGrad(actor, batchObs, rngKey)
        actorOptimizer.update(model: actor, gradients: actorGrads)
        
        return (actorLossValue, meanLogPi)
    }
    
    private func updateInternal(syncScalars: Bool) -> (qLoss: Float, actorLoss: Float, alphaLoss: Float)? {
        guard memory.count >= batchSize else { return nil }
        
        steps += 1
        
        let (batchObs, batchNextObs, batchActions, batchRewards, batchTerminated) = memory.sample(batchSize: batchSize)
        
        let batchRewardsFloat = batchRewards.asType(.float32)
        let batchTerminatedFloat = batchTerminated.asType(.float32)
        
        let key = MLX.key(UInt64(steps))
        let (k1, k2) = MLX.split(key: key)
        
        let alphaVal = exp(logAlphaModule.value)
        
        let totalQLoss = updateQ(
            batchObs: batchObs,
            batchNextObs: batchNextObs,
            batchActions: batchActions,
            batchRewards: batchRewardsFloat,
            batchTerminated: batchTerminatedFloat,
            rngKey: k1,
            alphaVal: alphaVal
        )
        
        let (actorLossValue, meanLogPi) = updateActor(
            batchObs: batchObs,
            rngKey: k2,
            alphaVal: alphaVal
        )
        
        softUpdateTargetNetwork()
        
        let currentAlpha = exp(logAlphaModule.value)
        let entropyDiff = (stopGradient(meanLogPi) - targetEntropyArray).mean()
        let alphaLossArray = -currentAlpha * entropyDiff
        logAlphaModule.value = logAlphaModule.value + alphaLearningRate * currentAlpha * entropyDiff
        logAlphaModule.value = minimum(maximum(logAlphaModule.value, minLogAlphaArray), maxLogAlphaArray)
        
        eval(totalQLoss, actorLossValue, alphaLossArray, actor, qEnsemble, qEnsembleTarget, logAlphaModule)
        
        if syncScalars {
            _ = syncAlpha()
            
            return (totalQLoss.item(Float.self), actorLossValue.item(Float.self), alphaLossArray.item(Float.self))
        } else {
            return nil
        }
    }
    
    public func updateNoSync() {
        _ = updateInternal(syncScalars: false)
    }
    
    public func update() -> (qLoss: Float, actorLoss: Float, alphaLoss: Float)? {
        updateInternal(syncScalars: true)
    }
    
    public func updateWithBatch(
        batchObs: MLXArray,
        batchNextObs: MLXArray,
        batchActions: MLXArray,
        batchRewards: MLXArray,
        batchTerminated: MLXArray,
        rngKey: MLXArray
    ) -> MLXArray {
        steps += 1
        
        let batchRewardsFloat = batchRewards.asType(.float32)
        let batchTerminatedFloat = batchTerminated.asType(.float32)
        
        let (k1, k2) = MLX.split(key: rngKey)
        
        let alphaVal = exp(logAlphaModule.value)
        
        let totalQLoss = updateQ(
            batchObs: batchObs,
            batchNextObs: batchNextObs,
            batchActions: batchActions,
            batchRewards: batchRewardsFloat,
            batchTerminated: batchTerminatedFloat,
            rngKey: k1,
            alphaVal: alphaVal
        )
        
        let (actorLossValue, meanLogPi) = updateActor(
            batchObs: batchObs,
            rngKey: k2,
            alphaVal: alphaVal
        )
        
        softUpdateTargetNetwork()
        
        let currentAlpha = exp(logAlphaModule.value)
        let entropyDiff = (stopGradient(meanLogPi) - targetEntropyArray).mean()
        logAlphaModule.value = logAlphaModule.value + alphaLearningRate * currentAlpha * entropyDiff
        logAlphaModule.value = minimum(maximum(logAlphaModule.value, minLogAlphaArray), maxLogAlphaArray)
        
        return totalQLoss + actorLossValue
    }
    
    private func softUpdateTargetNetwork() {
        softUpdate(target: qEnsembleTarget, source: qEnsemble, tau: tau)
    }
}

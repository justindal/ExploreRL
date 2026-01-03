//
//  MountainCarContinuousSAC.swift
//  ExploreRL
//
//  SAC agent specialized for MountainCarContinuous environment
//  Observation space: 2 (position, velocity)
//  Action space: 1 (force in [-1, 1])
//

import Foundation
import MLX
import MLXNN
import MLXOptimizers
import RealModule

/// Actor network for MountainCarContinuous environment with Gaussian policy
nonisolated public class MountainCarContinuousActorNetwork: Module, SACActorProtocol {
    let layer1: Linear
    let layer2: Linear
    let meanLayer: Linear
    let logStdLayer: Linear
    let learnedStd: Bool
    let useGSDE: Bool
    let logStdParam: TrainableParameter?
    
    private var explorationMat: MLXArray?

    nonisolated public let actionScale: MLXArray
    nonisolated public let actionBias: MLXArray
    
    private let fixedLogStd: Float = -1.0
    private let logStdMinArray: MLXArray
    private let logStdRangeHalf: MLXArray
    private let logPiConstant: MLXArray
    private let epsilon: MLXArray

    public init(
        numObservations: Int,
        numActions: Int,
        hiddenSize: Int = 256,
        actionSpaceLow: Float = -1.0,
        actionSpaceHigh: Float = 1.0,
        learnedStd: Bool = true,
        logStdInit: Float = -3.67,
        useGSDE: Bool = false
    ) {
        let logStdMax: Float = 2.0
        let logStdMin: Float = -5.0
        
        self.layer1 = kaimingLinear(numObservations, hiddenSize)
        self.layer2 = kaimingLinear(hiddenSize, hiddenSize)
        self.meanLayer = Linear(hiddenSize, numActions)
        self.learnedStd = learnedStd
        self.useGSDE = useGSDE
        if useGSDE {
            self.logStdParam = TrainableParameter(
                MLXArray(Array(repeating: logStdInit, count: hiddenSize * numActions))
                    .reshaped([hiddenSize, numActions])
            )
        } else {
            self.logStdParam = nil
        }

        let logStdBias: MLXArray? = {
            guard learnedStd, numActions > 0 else { return MLX.zeros([numActions]) }
            let denom = Float(0.5 * (logStdMax - logStdMin))
            let center = logStdMin + denom
            let desiredTanh = max(-0.999, min(0.999, (logStdInit - center) / denom))
            let biasValue = atanh(desiredTanh)
            return MLXArray(Array(repeating: biasValue, count: numActions))
        }()
        let tmpLogStd = Linear(hiddenSize, numActions)
        self.logStdLayer = Linear(weight: tmpLogStd.weight, bias: logStdBias)

        let scale = (actionSpaceHigh - actionSpaceLow) / 2.0
        let bias = (actionSpaceHigh + actionSpaceLow) / 2.0
        self.actionScale = MLXArray(scale)
        self.actionBias = MLXArray(bias)
        
        self.logStdMinArray = MLXArray(logStdMin)
        self.logStdRangeHalf = MLXArray(0.5 * (logStdMax - logStdMin))
        self.logPiConstant = MLXArray(Float.log(2.0 * Float.pi))
        self.epsilon = MLXArray(Float(1e-6))
        
        super.init()
    }

    public func resetNoise(key: inout MLXArray) {
        guard useGSDE, let logStdParam else { return }
        let (k1, k2) = MLX.split(key: key)
        key = k2
        
        let std = exp(logStdParam.value) // [latent_sde_dim, action_dim]
        let eps = MLX.normal(std.shape, key: k1)
        explorationMat = eps * std
    }

    public func callAsFunction(_ x: MLXArray) -> (mean: MLXArray, logStd: MLXArray) {
        var h = relu(layer1(x))
        h = relu(layer2(h))
        let mean = meanLayer(h)
        let logStd: MLXArray
        if learnedStd {
            var l = logStdLayer(h)
            l = tanh(l)
            logStd = logStdMinArray + logStdRangeHalf * (l + 1.0)
        } else {
            logStd = MLXArray(fixedLogStd)
        }
        return (mean, logStd)
    }

    public func sample(obs: MLXArray, key: MLXArray) -> (action: MLXArray, logProb: MLXArray, mean: MLXArray) {
        var h = relu(layer1(obs))
        h = relu(layer2(h))
        let mean = meanLayer(h)
        
        if useGSDE, let logStdParam {
            let latentSde = stopGradient(h) 
            let stdMat = exp(logStdParam.value)
            
            let variance = matmul(pow(latentSde, 2.0), pow(stdMat, 2.0))
            let distStd = sqrt(variance + epsilon)
            let logStdForProb = log(distStd)
            
            let noise: MLXArray
            if latentSde.shape.count == 2,
               latentSde.shape[0] == 1,
               let explorationMat {
                noise = matmul(latentSde, explorationMat)
            } else {
                let batch = latentSde.shape[0]
                let eps = MLX.normal([batch] + stdMat.shape, key: key)
                let explorationMatrices = eps * stdMat.reshaped([1] + stdMat.shape)
                let latentB = latentSde.reshaped([batch, 1, latentSde.shape[1]])
                let out = matmul(latentB, explorationMatrices)
                noise = out.reshaped([batch, mean.shape[1]])
            }
            
            let x_t = mean + noise
            let y_t = tanh(x_t)
            let action = y_t * actionScale + actionBias
            
            let logProbNorm = -0.5 * (pow((x_t - mean) / distStd, 2.0) + 2.0 * logStdForProb + logPiConstant)
            let logProbCorrection = log(1.0 - pow(y_t, 2.0) + epsilon)
            let logProb = (logProbNorm - logProbCorrection).sum(axis: -1, keepDims: true)
            return (action, logProb, mean)
        }
        
        let logStd: MLXArray
        if learnedStd {
            var l = logStdLayer(h)
            l = tanh(l)
            logStd = logStdMinArray + logStdRangeHalf * (l + 1.0)
        } else {
            logStd = MLXArray(fixedLogStd)
        }
        let std = exp(logStd)
        
        let noise = MLX.normal(mean.shape, key: key)
        let x_t = mean + std * noise
        let y_t = tanh(x_t)
        
        let action = y_t * actionScale + actionBias
        
        let logProbNorm = -0.5 * (pow((x_t - mean) / std, 2.0) + 2.0 * logStd + logPiConstant)
        let logProbCorrection = log(1.0 - pow(y_t, 2.0) + epsilon)
        let logProb = (logProbNorm - logProbCorrection).sum(axis: -1, keepDims: true)
        
        return (action, logProb, mean)
    }
    
    public func getDeterministicAction(obs: MLXArray) -> MLXArray {
        let (mean, _) = self(obs)
        return tanh(mean) * actionScale + actionBias
    }
}

/// Ensemble Q-Network for MountainCarContinuous environment using vmap
nonisolated public class MountainCarContinuousEnsembleQNetwork: Module, SACEnsembleCriticProtocol {
    let layer1: Linear
    let layer2: Linear
    let layer3: Linear
    
    public let numEnsemble: Int
    public let hiddenSize: Int
    
    private var vmappedForward: (([MLXArray]) -> [MLXArray])?
    
    public init(numObservations: Int, numActions: Int, numEnsemble: Int = 2, hiddenSize: Int = 256) {
        self.numEnsemble = numEnsemble
        self.hiddenSize = hiddenSize
        
        let inputSize = numObservations + numActions
        
        let (w1, b1) = kaimingEnsembleWeights(inputDimensions: inputSize, outputDimensions: hiddenSize, numEnsemble: numEnsemble)
        self.layer1 = Linear(weight: w1, bias: b1)
        
        let (w2, b2) = kaimingEnsembleWeights(inputDimensions: hiddenSize, outputDimensions: hiddenSize, numEnsemble: numEnsemble)
        self.layer2 = Linear(weight: w2, bias: b2)
        
        let (w3, b3) = kaimingEnsembleWeights(inputDimensions: hiddenSize, outputDimensions: 1, numEnsemble: numEnsemble)
        self.layer3 = Linear(weight: w3, bias: b3)
        
        super.init()
    }
    
    private static func singleForward(arrays: [MLXArray]) -> [MLXArray] {
        let x = arrays[0]
        let w1 = arrays[1]
        let b1 = arrays[2]
        let w2 = arrays[3]
        let b2 = arrays[4]
        let w3 = arrays[5]
        let b3 = arrays[6]
        
        var h = matmul(x, w1.transposed()) + b1
        h = relu(h)
        h = matmul(h, w2.transposed()) + b2
        h = relu(h)
        let out = matmul(h, w3.transposed()) + b3
        return [out]
    }
    
    private func getVmappedForward() -> ([MLXArray]) -> [MLXArray] {
        if let existing = vmappedForward {
            return existing
        }
        
        let mapped = vmap(
            MountainCarContinuousEnsembleQNetwork.singleForward,
            inAxes: [nil, 0, 0, 0, 0, 0, 0],
            outAxes: [0]
        )
        vmappedForward = mapped
        return mapped
    }
    
    public func callAsFunction(obs: MLXArray, action: MLXArray) -> MLXArray {
        let x = concatenated([obs, action], axis: -1)
        
        let w1 = layer1.weight
        let b1 = layer1.bias!
        let w2 = layer2.weight
        let b2 = layer2.bias!
        let w3 = layer3.weight
        let b3 = layer3.bias!
        
        let vf = getVmappedForward()
        let results = vf([x, w1, b1, w2, b2, w3, b3])
        return results[0]
    }
    
    public func minQ(obs: MLXArray, action: MLXArray) -> MLXArray {
        let allQ = self.callAsFunction(obs: obs, action: action)
        return allQ.min(axis: 0)
    }
}

public class MountainCarContinuousSAC: SACAgentVmap<MountainCarContinuousActorNetwork, MountainCarContinuousEnsembleQNetwork> {
    public let hiddenSize: Int
    
    // MountainCarContinuous environment constants
    public static let observationSize = 2
    public static let actionCount = 1
    public static let actionLow: Float = -1.0
    public static let actionHigh: Float = 1.0
    
    public struct Defaults {
        public static let hiddenSize = 256
        public static let learningRate: Float = 0.0003
        public static let gamma: Float = 0.99
        public static let tau: Float = 0.005
        public static let batchSize = 256
        public static let bufferSize = 100000
    }
    
    public init(
        hiddenSize: Int = Defaults.hiddenSize,
        learningRate: Float = Defaults.learningRate,
        gamma: Float = Defaults.gamma,
        tau: Float = Defaults.tau,
        batchSize: Int = Defaults.batchSize,
        bufferSize: Int = Defaults.bufferSize,
        learnedStd: Bool = true,
        entCoefMode: EntropyCoefficientMode = .auto(initAlpha: 1.0, alphaLr: 0.0003, targetEntropy: nil),
        logStdInit: Float = -3.67,
        useGSDE: Bool = false
    ) {
        self.hiddenSize = hiddenSize
        let actorNet = MountainCarContinuousActorNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize,
            actionSpaceLow: Self.actionLow,
            actionSpaceHigh: Self.actionHigh,
            learnedStd: learnedStd,
            logStdInit: logStdInit,
            useGSDE: useGSDE
        )
        
        let qEnsemble = MountainCarContinuousEnsembleQNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            numEnsemble: 2,
            hiddenSize: hiddenSize
        )
        let qEnsembleTarget = MountainCarContinuousEnsembleQNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            numEnsemble: 2,
            hiddenSize: hiddenSize
        )
        
        super.init(
            actor: actorNet,
            qEnsemble: qEnsemble,
            qEnsembleTarget: qEnsembleTarget,
            stateSize: Self.observationSize,
            actionSize: Self.actionCount,
            learningRate: learningRate,
            gamma: gamma,
            tau: tau,
            batchSize: batchSize,
            bufferSize: bufferSize,
            entCoefMode: entCoefMode
        )
    }
}

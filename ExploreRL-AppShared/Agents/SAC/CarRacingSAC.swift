import Foundation
import MLX
import MLXNN
import MLXOptimizers
import RealModule

nonisolated public class CarRacingActorNetwork: Module, SACActorProtocol {
    let layer1: Linear
    let layer2: Linear
    let meanLayer: Linear
    let logStdLayer: Linear

    nonisolated public let actionScale: MLXArray
    nonisolated public let actionBias: MLXArray
    
    private let logStdMax: Float = 2.0
    private let logStdMin: Float = -5.0
    private let logStdMinArray: MLXArray
    private let logStdRangeHalf: MLXArray
    private let logPiConstant: MLXArray
    private let epsilon: MLXArray
    
    public let useSDE: Bool
    public let numActions: Int
    private var sdeNoise: MLXArray?

    public init(
        numObservations: Int,
        numActions: Int,
        hiddenSize: Int = 256,
        useSDE: Bool = false
    ) {
        self.useSDE = useSDE
        self.numActions = numActions
        self.sdeNoise = nil
        
        self.layer1 = kaimingLinear(numObservations, hiddenSize)
        self.layer2 = kaimingLinear(hiddenSize, hiddenSize)
        self.meanLayer = Linear(hiddenSize, numActions)
        self.logStdLayer = Linear(hiddenSize, numActions)

        self.actionScale = MLXArray([1.0, 0.5, 0.5] as [Float32])
        self.actionBias = MLXArray([0.0, 0.5, 0.5] as [Float32])
        
        self.logStdMinArray = MLXArray(logStdMin)
        self.logStdRangeHalf = MLXArray(0.5 * (logStdMax - logStdMin))
        self.logPiConstant = MLXArray(Float.log(2.0 * Float.pi))
        self.epsilon = MLXArray(Float(1e-6))
        
        super.init()
    }
    
    public func resetNoise(key: MLXArray) {
        self.sdeNoise = MLX.normal([1, numActions], key: key)
    }

    public func callAsFunction(_ x: MLXArray) -> (mean: MLXArray, logStd: MLXArray) {
        var h = relu(layer1(x))
        h = relu(layer2(h))
        let mean = meanLayer(h)
        var logStd = logStdLayer(h)
        logStd = tanh(logStd)
        logStd = logStdMinArray + logStdRangeHalf * (logStd + 1.0)
        return (mean, logStd)
    }

    public func sample(obs: MLXArray, key: MLXArray) -> (action: MLXArray, logProb: MLXArray, mean: MLXArray) {
        let (mean, logStd) = self(obs)
        let std = exp(logStd)

        let noise: MLXArray
        if useSDE, let persistentNoise = sdeNoise {
            noise = MLX.broadcast(persistentNoise, to: mean.shape)
        } else {
            noise = MLX.normal(mean.shape, key: key)
        }
        
        let x_t = mean + std * noise
        let y_t = tanh(x_t)

        let action = y_t * actionScale + actionBias

        let logProbNorm = -0.5 * (pow((x_t - mean) / std, 2.0) + 2.0 * logStd + logPiConstant)
        let logProbCorrection = log(1.0 - pow(y_t, 2.0) + epsilon)
        let logScale = log(actionScale).sum()
        let logProb = (logProbNorm - logProbCorrection).sum(axis: -1, keepDims: true) - logScale
        
        return (action, logProb, mean)
    }
    
    public func getDeterministicAction(obs: MLXArray) -> MLXArray {
        let (mean, _) = self(obs)
        return tanh(mean) * actionScale + actionBias
    }
}

nonisolated public class CarRacingEnsembleQNetwork: Module, SACEnsembleCriticProtocol {
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
            CarRacingEnsembleQNetwork.singleForward,
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

public class CarRacingSAC: SACAgentVmap<CarRacingActorNetwork, CarRacingEnsembleQNetwork> {
    
    public static let defaultObservationSize = 144
    public static let actionCount = 3
    
    public let observationSize: Int
    public let useSDE: Bool
    
    public struct Defaults {
        public static let hiddenSize = 256
        public static let learningRate: Float = 0.00073
        public static let gamma: Float = 0.99
        public static let tau: Float = 0.02
        public static let batchSize = 256
        public static let bufferSize = 300000
    }
    
    public init(
        observationSize: Int = defaultObservationSize,
        hiddenSize: Int = Defaults.hiddenSize,
        learningRate: Float = Defaults.learningRate,
        gamma: Float = Defaults.gamma,
        tau: Float = Defaults.tau,
        batchSize: Int = Defaults.batchSize,
        bufferSize: Int = Defaults.bufferSize,
        useSDE: Bool = true,
        entCoefMode: EntropyCoefficientMode = .auto(initAlpha: 1.0, alphaLr: 0.0003, targetEntropy: nil)
    ) {
        self.observationSize = observationSize
        self.useSDE = useSDE
        
        let actorNet = CarRacingActorNetwork(
            numObservations: observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize,
            useSDE: useSDE
        )
        
        let qEnsemble = CarRacingEnsembleQNetwork(
            numObservations: observationSize,
            numActions: Self.actionCount,
            numEnsemble: 2,
            hiddenSize: hiddenSize
        )
        let qEnsembleTarget = CarRacingEnsembleQNetwork(
            numObservations: observationSize,
            numActions: Self.actionCount,
            numEnsemble: 2,
            hiddenSize: hiddenSize
        )
        
        super.init(
            actor: actorNet,
            qEnsemble: qEnsemble,
            qEnsembleTarget: qEnsembleTarget,
            stateSize: observationSize,
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


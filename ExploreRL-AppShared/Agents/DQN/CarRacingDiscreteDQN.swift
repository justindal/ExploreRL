import Foundation
import MLX
import MLXNN
import MLXOptimizers

nonisolated public class CarRacingDiscreteQNetwork: Module, QNetworkProtocol {
    let layer1: Linear
    let layer2: Linear
    let layer3: Linear

    public init(numObservations: Int, numActions: Int, hiddenSize: Int = 256) {
        self.layer1 = kaimingLinear(numObservations, hiddenSize)
        self.layer2 = kaimingLinear(hiddenSize, hiddenSize)
        self.layer3 = kaimingLinear(hiddenSize, numActions)
        super.init()
    }

    public func callAsFunction(_ x: MLXArray) -> MLXArray {
        var x = x
        x = relu(layer1(x))
        x = relu(layer2(x))
        return layer3(x)
    }
}

public class CarRacingDiscreteDQN: DQNAgent<CarRacingDiscreteQNetwork> {
    
    public static let defaultObservationSize = 144
    public static let actionCount = 5
    
    public let observationSize: Int
    
    public struct Defaults {
        public static let hiddenSize = 256
        public static let learningRate: Float = 0.0003
        public static let gamma: Float = 0.99
        public static let epsilonStart: Float = 1.0
        public static let epsilonEnd: Float = 0.05
        public static let epsilonDecaySteps = 100000
        public static let targetUpdateFrequency = 1000
        public static let batchSize = 64
        public static let bufferCapacity = 100000
        public static let gradClipNorm: Float = 10.0
    }
    
    public init(
        observationSize: Int = defaultObservationSize,
        hiddenSize: Int = Defaults.hiddenSize,
        learningRate: Float = Defaults.learningRate,
        gamma: Float = Defaults.gamma,
        epsilonStart: Float = Defaults.epsilonStart,
        epsilonEnd: Float = Defaults.epsilonEnd,
        epsilonDecaySteps: Int = Defaults.epsilonDecaySteps,
        targetUpdateFrequency: Int = Defaults.targetUpdateFrequency,
        batchSize: Int = Defaults.batchSize,
        bufferCapacity: Int = Defaults.bufferCapacity,
        gradClipNorm: Float = Defaults.gradClipNorm
    ) {
        self.observationSize = observationSize
        
        let policyNet = CarRacingDiscreteQNetwork(
            numObservations: observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize
        )
        let targetNet = CarRacingDiscreteQNetwork(
            numObservations: observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize
        )
        
        super.init(
            policyNetwork: policyNet,
            targetNetwork: targetNet,
            batchSize: batchSize,
            stateSize: observationSize,
            actionSize: Self.actionCount,
            gamma: gamma,
            epsilonStart: epsilonStart,
            epsilonEnd: epsilonEnd,
            epsilonDecaySteps: epsilonDecaySteps,
            targetUpdateStrategy: .hard(frequency: targetUpdateFrequency),
            learningRate: learningRate,
            optim: Adam(learningRate: learningRate),
            gradClipNorm: gradClipNorm,
            bufferCapacity: bufferCapacity
        )
    }
}


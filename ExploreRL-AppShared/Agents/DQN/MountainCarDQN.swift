//
//  MountainCarDQN.swift
//  ExploreRL
//
//  DQN agent specialized for MountainCar environment
//  Observation space: 2 (position, velocity)
//  Action space: 3 (push left, no push, push right)
//

import Foundation
import MLX
import MLXNN
import MLXOptimizers

/// Q-Network architecture for MountainCar environment
nonisolated public class MountainCarQNetwork: Module, QNetworkProtocol {
    let layer1: Linear
    let layer2: Linear
    let layer3: Linear
    let layer4: Linear

    public init(numObservations: Int, numActions: Int, hiddenSize: Int = 128) {
        self.layer1 = kaimingLinear(numObservations, hiddenSize)
        self.layer2 = kaimingLinear(hiddenSize, hiddenSize)
        self.layer3 = kaimingLinear(hiddenSize, hiddenSize)
        self.layer4 = kaimingLinear(hiddenSize, numActions)
        super.init()
    }

    public func callAsFunction(_ x: MLXArray) -> MLXArray {
        var x = x
        x = relu(layer1(x))
        x = relu(layer2(x))
        x = relu(layer3(x))
        return layer4(x)
    }
}

public class MountainCarDQN: DQNAgent<MountainCarQNetwork> {
    
    // MountainCar environment constants
    public static let observationSize = 2
    public static let actionCount = 3
    
    // Default hyperparameters tuned for MountainCar
    public struct Defaults {
        public static let hiddenSize = 128
        public static let learningRate: Float = 0.00025
        public static let gamma: Float = 0.99
        public static let epsilonStart: Float = 1.0
        public static let epsilonEnd: Float = 0.01
        public static let epsilonDecaySteps = 50000
        public static let targetUpdateFrequency = 1000
        public static let batchSize = 64
        public static let bufferCapacity = 50000
        public static let gradClipNorm: Float = 10.0
    }
    
    public init(
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
        // Create MountainCar-specific networks
        let policyNet = MountainCarQNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize
        )
        let targetNet = MountainCarQNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize
        )
        
        super.init(
            policyNetwork: policyNet,
            targetNetwork: targetNet,
            batchSize: batchSize,
            stateSize: Self.observationSize,
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

//
//  CartPoleDQN.swift
//  ExploreRL
//
//  DQN agent specialized for CartPole environment
//  Observation space: 4 (cart position, cart velocity, pole angle, pole angular velocity)
//  Action space: 2 (push left, push right)
//

import Foundation
import MLX
import MLXNN
import MLXOptimizers

/// Q-Network architecture for CartPole environment
nonisolated public class CartPoleQNetwork: Module, QNetworkProtocol {
    let layer1: Linear
    let layer2: Linear
    let layer3: Linear

    public init(numObservations: Int, numActions: Int, hiddenSize: Int = 128) {
        self.layer1 = xavierLinear(numObservations, hiddenSize)
        self.layer2 = xavierLinear(hiddenSize, hiddenSize)
        self.layer3 = xavierLinear(hiddenSize, numActions)
        super.init()
    }

    public func callAsFunction(_ x: MLXArray) -> MLXArray {
        var x = x
        x = relu(layer1(x))
        x = relu(layer2(x))
        return layer3(x)
    }
}

public class CartPoleDQN: DQNAgent<CartPoleQNetwork> {
    
    // CartPole environment constants
    public static let observationSize = 4
    public static let actionCount = 2
    
    // Default hyperparameters tuned for CartPole
    public struct Defaults {
        public static let hiddenSize = 128
        public static let learningRate: Float = 0.001
        public static let gamma: Float = 0.99
        public static let epsilonStart: Float = 1.0
        public static let epsilonEnd: Float = 0.01
        public static let epsilonDecaySteps = 10000
        public static let targetUpdateFrequency = 500 
        public static let batchSize = 64
        public static let bufferCapacity = 10000
        public static let gradClipNorm: Float = 100.0
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
        // Create CartPole-specific networks
        let policyNet = CartPoleQNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize
        )
        let targetNet = CartPoleQNetwork(
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

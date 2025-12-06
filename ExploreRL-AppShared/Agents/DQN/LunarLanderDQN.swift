//
//  LunarLanderDQN.swift
//
//  DQN agent specialized for LunarLander-v3 environment
//  Observation space: 8 (x, y, vx, vy, angle, angular velocity, left leg contact, right leg contact)
//  Action space: 4 (do nothing, fire left, fire main, fire right)
//

import Foundation
import MLX
import MLXNN
import MLXOptimizers

/// Q-Network architecture for LunarLander environment
nonisolated public class LunarLanderQNetwork: Module, QNetworkProtocol {
    let layer1: Linear
    let layer2: Linear
    let layer3: Linear

    public init(numObservations: Int, numActions: Int, hiddenSize: Int = 256) {
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

public class LunarLanderDQN: DQNAgent<LunarLanderQNetwork> {
    
    public static let observationSize = 8
    public static let actionCount = 4
    
    public struct Defaults {
        public static let hiddenSize = 256
        public static let learningRate: Float = 0.0005
        public static let gamma: Float = 0.99
        public static let epsilonStart: Float = 1.0
        public static let epsilonEnd: Float = 0.01
        public static let epsilonDecaySteps = 50000
        public static let tau: Float = 0.005
        public static let batchSize = 64
        public static let bufferCapacity = 100000
        public static let gradClipNorm: Float = 10.0
    }
    
    public init(
        hiddenSize: Int = Defaults.hiddenSize,
        learningRate: Float = Defaults.learningRate,
        gamma: Float = Defaults.gamma,
        epsilonStart: Float = Defaults.epsilonStart,
        epsilonEnd: Float = Defaults.epsilonEnd,
        epsilonDecaySteps: Int = Defaults.epsilonDecaySteps,
        tau: Float = Defaults.tau,
        batchSize: Int = Defaults.batchSize,
        bufferCapacity: Int = Defaults.bufferCapacity,
        gradClipNorm: Float = Defaults.gradClipNorm
    ) {
        let policyNet = LunarLanderQNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize
        )
        let targetNet = LunarLanderQNetwork(
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
            targetUpdateStrategy: .soft(tau: tau),
            learningRate: learningRate,
            optim: Adam(learningRate: learningRate),
            gradClipNorm: gradClipNorm,
            bufferCapacity: bufferCapacity
        )
    }
}

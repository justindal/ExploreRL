//
//  AcrobotDQN.swift
//  ExploreRL
//
//  DQN agent specialized for Acrobot-v1 environment
//  Observation space: 6 (cos(theta1), sin(theta1), cos(theta2), sin(theta2), theta1_dot, theta2_dot)
//  Action space: 3 (torque -1, 0, +1)
//

import Foundation
import MLX
import MLXNN
import MLXOptimizers

/// Q-Network architecture for Acrobot environment
nonisolated public class AcrobotQNetwork: Module, QNetworkProtocol {
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

public class AcrobotDQN: DQNAgent<AcrobotQNetwork> {
    
    // Acrobot-v1 environment constants
    public static let observationSize = 6
    public static let actionCount = 3
    
    // Default hyperparameters tuned for Acrobot
    public struct Defaults {
        public static let hiddenSize = 128
        public static let learningRate: Float = 0.001
        public static let gamma: Float = 0.99
        public static let epsilonStart: Float = 1.0
        public static let epsilonEnd: Float = 0.01
        public static let epsilonDecaySteps = 10000
        public static let tau: Float = 0.005
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
        tau: Float = Defaults.tau,
        batchSize: Int = Defaults.batchSize,
        bufferCapacity: Int = Defaults.bufferCapacity,
        gradClipNorm: Float = Defaults.gradClipNorm
    ) {
        let policyNet = AcrobotQNetwork(
            numObservations: Self.observationSize,
            numActions: Self.actionCount,
            hiddenSize: hiddenSize
        )
        let targetNet = AcrobotQNetwork(
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

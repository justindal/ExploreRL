//
//  DeepRLAgent.swift
//  ExploreRL
//

import Foundation
import MLX
import Gymnazo

/// Protocol for discrete action space deep RL agents
public protocol DiscreteDeepRLAgent: AnyObject {
    var epsilon: Float { get set }
    
    func chooseAction(
        state: MLXArray,
        actionSpace: Discrete,
        key: inout MLXArray
    ) -> MLXArray
    
    func store(
        state: MLXArray,
        action: MLXArray,
        reward: Float,
        nextState: MLXArray,
        terminated: Bool
    )
    
    @discardableResult
    func update() -> (loss: Float, meanQ: Float, gradNorm: Float, tdError: Float)?
}

/// Protocol for continuous action space deep RL agents
public protocol ContinuousDeepRLAgent: AnyObject {
    func chooseAction(
        state: MLXArray,
        key: inout MLXArray,
        deterministic: Bool
    ) -> MLXArray
    
    func store(
        state: MLXArray,
        action: MLXArray,
        reward: Float,
        nextState: MLXArray,
        terminated: Bool
    )
    
    @discardableResult
    func update() -> (qLoss: Float, actorLoss: Float, alphaLoss: Float)?
}

public typealias DeepRLAgent = DiscreteDeepRLAgent


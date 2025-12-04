//
//  NetworkUtils.swift
//  ExploreRL
//
//  Shared utilities for neural network construction
//  Provides weight initialization strategies and common layer helpers
//

import Foundation
import MLX
import MLXNN

/// Creates a Linear layer with Xavier/Glorot uniform initialization
/// Best for layers with tanh or sigmoid activations
/// Formula: U(-sqrt(6/(fan_in+fan_out)), sqrt(6/(fan_in+fan_out)))
nonisolated public func xavierLinear(_ inputDimensions: Int, _ outputDimensions: Int, bias: Bool = true) -> Linear {
    let bound = sqrt(6.0 / Float(inputDimensions + outputDimensions))
    let weight = MLX.uniform(
        low: -bound,
        high: bound,
        [outputDimensions, inputDimensions]
    )
    let biasArray: MLXArray? = bias ? MLX.zeros([outputDimensions]) : nil
    return Linear(weight: weight, bias: biasArray)
}

/// Creates a Linear layer with Kaiming/He uniform initialization
/// Best for layers with ReLU activations
/// Formula: U(-sqrt(6/fan_in), sqrt(6/fan_in))
nonisolated public func kaimingLinear(_ inputDimensions: Int, _ outputDimensions: Int, bias: Bool = true) -> Linear {
    let gain = Float(sqrt(2.0))
    let bound = gain * sqrt(6.0 / Float(inputDimensions))
    let weight = MLX.uniform(
        low: -bound,
        high: bound,
        [outputDimensions, inputDimensions]
    )
    let biasArray: MLXArray? = bias ? MLX.zeros([outputDimensions]) : nil
    return Linear(weight: weight, bias: biasArray)
}

/// Creates Xavier-initialized weights for an ensemble of networks
/// Returns (weight, bias) arrays with shape [numEnsemble, outputDim, inputDim] and [numEnsemble, outputDim]
nonisolated public func xavierEnsembleWeights(
    inputDimensions: Int,
    outputDimensions: Int,
    numEnsemble: Int
) -> (weight: MLXArray, bias: MLXArray) {
    let bound = Float(sqrt(6.0 / Float(inputDimensions + outputDimensions)))
    let weight = MLX.uniform(low: -bound, high: bound, [numEnsemble, outputDimensions, inputDimensions])
    let bias = MLX.zeros([numEnsemble, outputDimensions])
    return (weight, bias)
}

/// Creates Kaiming-initialized weights for an ensemble of networks
nonisolated public func kaimingEnsembleWeights(
    inputDimensions: Int,
    outputDimensions: Int,
    numEnsemble: Int
) -> (weight: MLXArray, bias: MLXArray) {
    let bound = Float(sqrt(6.0 / Float(inputDimensions)))
    let weight = MLX.uniform(low: -bound, high: bound, [numEnsemble, outputDimensions, inputDimensions])
    let bias = MLX.zeros([numEnsemble, outputDimensions])
    return (weight, bias)
}

/// Performs soft update: θ_target ← τ * θ_source + (1 - τ) * θ_target
nonisolated public func softUpdate(target: Module, source: Module, tau: Float) {
    let tauArray = MLXArray(tau)
    let oneMinusTauArray = MLXArray(1.0 - tau)
    
    let sourceParams = source.parameters().flattened()
    let targetParams = target.parameters().flattened()
    let sourceDict = Dictionary(uniqueKeysWithValues: sourceParams)
    
    var updatedParams = [(String, MLXArray)]()
    updatedParams.reserveCapacity(targetParams.count)
    
    for (key, targetParam) in targetParams {
        if let sourceParam = sourceDict[key] {
            let updated = oneMinusTauArray * targetParam + tauArray * sourceParam
            updatedParams.append((key, updated))
        }
    }
    
    let newParams = NestedDictionary<String, MLXArray>.unflattened(updatedParams)
    target.update(parameters: newParams)
}

/// Performs hard update: θ_target ← θ_source
nonisolated public func hardUpdate(target: Module, source: Module) {
    target.update(parameters: source.parameters())
}

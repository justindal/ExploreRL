//
//  TabularHyperparameters.swift
//  ExploreRL
//

import Foundation

struct TabularHyperparameters: Equatable, Codable {
    var learningRate: Double = 0.1
    var gamma: Double = 0.99
    var epsilon: Double = 1.0
    var epsilonDecay: Double = 0.999
    var minEpsilon: Double = 0.05

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        learningRate = try c.decodeIfPresent(Double.self, forKey: .learningRate) ?? 0.1
        gamma = try c.decodeIfPresent(Double.self, forKey: .gamma) ?? 0.99
        epsilon = try c.decodeIfPresent(Double.self, forKey: .epsilon) ?? 1.0
        epsilonDecay = try c.decodeIfPresent(Double.self, forKey: .epsilonDecay) ?? 0.999
        minEpsilon = try c.decodeIfPresent(Double.self, forKey: .minEpsilon) ?? 0.05
    }
}

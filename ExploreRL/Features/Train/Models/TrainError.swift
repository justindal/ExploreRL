//
//  TrainError.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-03.
//

import Foundation

enum TrainError: Error {
    case unsupportedEnvironment(String)
    case invalidConfiguration(String)
    case environmentNotLoaded
    case noAlgorithmToSave
    case sessionLoadFailed(String)
}

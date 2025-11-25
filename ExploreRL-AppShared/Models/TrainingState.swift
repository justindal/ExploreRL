//
//  TrainingState.swift
//

import SwiftUI

/// Global training state observable to prevent accidental navigation away during active training.
@Observable
final class TrainingState {
    static let shared = TrainingState()
    
    var isTraining: Bool = false
    var activeEnvironment: String? = nil
    
    private init() {}
    
    func startTraining(environment: String) {
        isTraining = true
        activeEnvironment = environment
    }
    
    func stopTraining() {
        isTraining = false
        activeEnvironment = nil
    }
}


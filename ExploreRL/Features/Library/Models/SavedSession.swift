//
//  SavedSession.swift
//  ExploreRL
//

import Foundation

struct SavedSession: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let environmentID: String
    let algorithmType: AlgorithmType
    let trainingConfig: TrainingConfig
    let trainingState: TrainingState
    let envSettings: [String: SettingValue]
    let savedAt: Date
}

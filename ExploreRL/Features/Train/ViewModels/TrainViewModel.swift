//
//  TrainViewModel.swift
//  ExploreRL
//

import Foundation
import Gymnazo

@Observable
final class TrainViewModel {

    var envStates: [String: EnvLoadState] = [:]
    var envSettings: [String: [String: SettingValue]] = [:]
    var trainingConfigs: [String: TrainingConfig] = [:]
    var trainingStates: [String: TrainingState] = [:]
    var renderSnapshots: [String: any Sendable] = [:]
    var reloadingEnvs: Set<String> = []
    var resettingEnvs: Set<String> = []
    var trainingTasks: [String: Task<Void, Never>] = [:]
    var flushTasks: [String: Task<Void, Never>] = [:]
    var accumulators: [String: TrainingAccumulator] = [:]
    var trainingTimings: [String: TrainingTiming] = [:]
    var tabularAgents: [String: TabularAgent] = [:]
    var dqnAlgorithms: [String: DQN] = [:]
    var sacAlgorithms: [String: SAC] = [:]

    func state(for id: String) -> EnvLoadState {
        envStates[id] ?? .idle
    }

    func env(for id: String) -> (any Env)? {
        if case .loaded(let env) = envStates[id] {
            return env
        }
        return nil
    }

    func isReloading(id: String) -> Bool {
        reloadingEnvs.contains(id)
    }

    func isResetting(id: String) -> Bool {
        resettingEnvs.contains(id)
    }

    func settings(for id: String) -> [String: SettingValue] {
        var defaults: [String: SettingValue] = [:]
        for setting in EnvSettingsConfig.settings(for: id) {
            defaults[setting.id] = setting.defaultValue
        }
        if let existing = envSettings[id] {
            for (key, value) in existing {
                defaults[key] = value
            }
        }
        return defaults
    }

    func updateSetting(for id: String, key: String, value: SettingValue) {
        if envSettings[id] == nil {
            envSettings[id] = settings(for: id)
        }
        envSettings[id]?[key] = value
    }

    func trainingConfig(for id: String) -> TrainingConfig {
        var config = trainingConfigs[id] ?? EnvironmentDefaults.config(for: id)

        if let env = env(for: id) {
            let available = availableAlgorithms(for: env)
            if !available.contains(config.algorithm), let first = available.first {
                config.algorithm = first
                trainingConfigs[id] = config
            }
        }

        return config
    }

    func availableAlgorithms(for env: any Env) -> [AlgorithmType] {
        let hasDiscreteActions = env.actionSpace is Discrete
        let hasContinuousActions = env.actionSpace is Box
        let hasDiscreteObservations = env.observationSpace is Discrete
        let isTabularOnly: Bool = {
            if let tuple = env.observationSpace as? Tuple {
                return tuple.spaces.allSatisfy { $0 is Discrete }
            }
            return false
        }()

        return AlgorithmType.allCases.filter { algo in
            if algo.requiresDiscreteActions && !hasDiscreteActions {
                return false
            }
            if algo.requiresContinuousActions && !hasContinuousActions {
                return false
            }
            if algo.requiresDiscreteObservations && !hasDiscreteObservations && !isTabularOnly {
                return false
            }
            if isTabularOnly && !algo.isTabular {
                return false
            }
            return true
        }
    }

    func updateTrainingConfig(for id: String, update: (inout TrainingConfig) -> Void) {
        let oldConfig = trainingConfigs[id] ?? EnvironmentDefaults.config(for: id)
        var config = oldConfig
        update(&config)
        trainingConfigs[id] = config

        let algorithmChanged = config.algorithm != oldConfig.algorithm
        let tabularChanged = config.tabular != oldConfig.tabular
        let dqnChanged = config.dqn != oldConfig.dqn
        let sacChanged = config.sac != oldConfig.sac

        if algorithmChanged {
            tabularAgents[id] = nil
            dqnAlgorithms[id] = nil
            sacAlgorithms[id] = nil
        } else if tabularChanged {
            tabularAgents[id] = nil
        } else if dqnChanged {
            dqnAlgorithms[id] = nil
        } else if sacChanged {
            sacAlgorithms[id] = nil
        }
    }

    func trainingState(for id: String) -> TrainingState {
        trainingStates[id] ?? TrainingState()
    }

    func updateTrainingState(for id: String, update: (inout TrainingState) -> Void) {
        var state = trainingStates[id] ?? TrainingState()
        update(&state)
        trainingStates[id] = state
    }

    func flushAccumulator(for id: String) {
        guard let accumulator = accumulators[id] else { return }
        let pending = accumulator.drain()

        let currentTimestep = trainingState(for: id).currentTimestep
        guard pending.timestep != currentTimestep
            || !pending.episodes.isEmpty
            || !pending.metrics.isEmpty
            || pending.renderSnapshot != nil
        else { return }

        updateTrainingState(for: id) { state in
            state.currentTimestep = pending.timestep
            state.explorationRate = pending.explorationRate

            for (reward, length) in pending.episodes {
                state.recordEpisode(reward: reward, length: length)
            }

            for metrics in pending.metrics {
                state.recordTrainMetrics(metrics)
            }

            if pending.renderSnapshot != nil {
                state.renderVersion += 1
            }
        }

        if let snapshot = pending.renderSnapshot {
            renderSnapshots[id] = snapshot
        }
    }

    func startFlushLoop(for id: String) {
        flushTasks[id]?.cancel()
        flushTasks[id] = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.flushAccumulator(for: id)
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    func stopFlushLoop(for id: String) {
        flushTasks[id]?.cancel()
        flushTasks[id] = nil
    }

    func clearAll() {
        for task in trainingTasks.values {
            task.cancel()
        }
        for task in flushTasks.values {
            task.cancel()
        }
        trainingTasks.removeAll()
        flushTasks.removeAll()
        accumulators.removeAll()
        trainingTimings.removeAll()
        tabularAgents.removeAll()
        dqnAlgorithms.removeAll()
        sacAlgorithms.removeAll()
        trainingStates.removeAll()
        envStates.removeAll()
        resettingEnvs.removeAll()
        envSettings.removeAll()
        trainingConfigs.removeAll()
        renderSnapshots.removeAll()
    }

    var openEnvIDs: [String] {
        envStates.compactMap { id, state in
            if case .loaded = state { return id }
            return nil
        }
    }
}

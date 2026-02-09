//
//  TrainViewModel+Environment.swift
//  ExploreRL
//

import Foundation
import Gymnazo

extension TrainViewModel {

    @MainActor
    func loadEnv(id: String) async {
        if case .loaded = envStates[id] {
            return
        }
        envStates[id] = .loading
        await createEnv(id: id)
    }

    @MainActor
    func reloadEnv(id: String) async {
        reloadingEnvs.insert(id)
        await createEnv(id: id)
        reloadingEnvs.remove(id)
    }

    @MainActor
    func createEnv(id: String) async {
        do {
            let options = envOptions(for: id)
            let maxSteps = frozenLakeMaxSteps(for: id)
            var env = try await Gymnazo.make(id, maxEpisodeSteps: maxSteps, options: options)
            env.renderMode = .human
            let resetOptions = envResetOptions(for: id)
            let resetSeed = envResetSeed(for: id)
            let resetPayload = resetOptions.isEmpty ? nil : resetOptions
            _ = try env.reset(seed: resetSeed, options: resetPayload)
            envStates[id] = .loaded(env)
            updateTrainingState(for: id) { $0.renderVersion += 1 }
        } catch {
            envStates[id] = .error(error)
        }
    }

    func envOptions(for id: String) -> EnvOptions {
        let currentSettings = settings(for: id)
        let baseName = id.split(separator: "-").first.map(String.init) ?? id
        var options = EnvOptions()

        if baseName.hasPrefix("FrozenLake") {
            let defaultSize = id.contains("8x8") ? 8 : 4
            let size = currentSettings["size"]?.intValue ?? defaultSize
            let holeProbability = currentSettings["hole_probability"]?.floatValue ?? 0.2
            let isSlippery = currentSettings["is_slippery"]?.boolValue ?? true
            let successRate = currentSettings["success_rate"]?.floatValue ?? Float(1.0 / 3.0)
            let customMap = currentSettings["custom_map"]?.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if !customMap.isEmpty {
                let rows = customMap
                    .components(separatedBy: CharacterSet(charactersIn: ",\n"))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !rows.isEmpty {
                    options["desc"] = rows
                }
            } else if size == 4 {
                options["map_name"] = "4x4"
            } else if size == 8 {
                options["map_name"] = "8x8"
            } else {
                let cached = currentSettings["_generated_desc"]?.stringValue ?? ""
                let cachedRows = cached.components(separatedBy: ",").filter { !$0.isEmpty }

                if cachedRows.count == size, cachedRows.first?.count == size {
                    options["desc"] = cachedRows
                } else {
                    let seed = envResetSeed(for: id).map { Int($0) }
                    let frozenProbability = 1.0 - holeProbability
                    let map = FrozenLake.generateRandomMap(
                        size: size, p: frozenProbability, seed: seed
                    )
                    options["desc"] = map
                    envSettings[id, default: [:]][
                        "_generated_desc"
                    ] = .string(map.joined(separator: ","))
                }
            }
            options["is_slippery"] = isSlippery
            options["success_rate"] = successRate
        } else {
            let resetKeys: Set<String> = [
                "seed",
                "x_init",
                "y_init",
                "low",
                "high",
                "randomize"
            ]
            for (key, value) in currentSettings {
                if resetKeys.contains(key) { continue }
                switch value {
                case .bool(let b):
                    options[key] = b
                case .float(let f):
                    options[key] = f
                case .string(let s):
                    options[key] = s
                case .int(let i):
                    options[key] = i
                }
            }
        }

        return options
    }

    private func frozenLakeMaxSteps(for id: String) -> Int? {
        let baseName = id.split(separator: "-").first.map(String.init) ?? id
        guard baseName.hasPrefix("FrozenLake") else { return nil }
        let defaultSize = id.contains("8x8") ? 8 : 4
        let size = settings(for: id)["size"]?.intValue ?? defaultSize
        guard size != 4, size != 8 else { return nil }
        return size * 25
    }

    func envResetOptions(for id: String) -> EnvOptions {
        let currentSettings = settings(for: id)
        let baseName = id.split(separator: "-").first.map(String.init) ?? id
        var options = EnvOptions()

        if baseName == "Pendulum" {
            if let xInit = currentSettings["x_init"]?.floatValue {
                options["x_init"] = xInit
            }
            if let yInit = currentSettings["y_init"]?.floatValue {
                options["y_init"] = yInit
            }
        } else if baseName == "Acrobot" {
            if let low = currentSettings["low"]?.floatValue {
                options["low"] = low
            }
            if let high = currentSettings["high"]?.floatValue {
                options["high"] = high
            }
        } else if baseName == "CarRacing" || baseName == "CarRacingDiscrete" {
            if let randomize = currentSettings["randomize"]?.boolValue {
                options["randomize"] = randomize
            }
        }

        return options
    }

    func envResetSeed(for id: String) -> UInt64? {
        let seedValue = settings(for: id)["seed"]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if seedValue.isEmpty { return nil }
        return UInt64(seedValue)
    }

    func updateEnv(id: String, env: any Env) {
        envStates[id] = .loaded(env)
    }

    func closeEnv(id: String) {
        envStates[id] = nil
    }
}

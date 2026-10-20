import Foundation
import Gymnazo

@Observable
final class EvaluateViewModel {

    var sessions: [SavedSession] = []
    var state = EvaluationState()
    var env: (any Env)?
    var renderSnapshot: (any Sendable)?
    var isEvaluationActive = true

    private var tabularAgent: TabularAgent?
    private var dqnAlgorithm: DQN?
    private var ppoAlgorithm: PPO?
    private var sacAlgorithm: SAC?
    private var td3Algorithm: TD3?
    private var valueEnv: AnyValueEnvironment?
    private var loadedSession: SavedSession?
    private var evalTask: Task<Void, Never>?
    private var loadRequestID = UUID()

    private let storage = SessionStorage.shared

    func loadSessions() {
        sessions = storage.listSessions()
    }

    @MainActor
    func loadSession(_ session: SavedSession, checkpointDirectory: URL? = nil) async {
        let requestID = UUID()
        loadRequestID = requestID
        state.reset()
        state.status = .loading
        env = nil
        renderSnapshot = nil
        await clearAlgorithm()
        guard loadRequestID == requestID else { return }

        do {
            try checkLoad(requestID)
            try SessionCompatibility.validate(session)
            var previewEnv = try await makeEnv(for: session)
            try checkLoad(requestID)
            _ = try previewEnv.reset(
                seed: envResetSeed(settings: session.envSettings),
                options: nil
            )

            let checkpointDir = checkpointDirectory ?? storage.checkpointDirectory(for: session.id)
            let nextValueEnv = try await makeValueEnv(for: session)
            try checkLoad(requestID)
            valueEnv = nextValueEnv

            env = previewEnv

            switch session.algorithmType {
            case .qLearning, .sarsa:
                let algorithmEnv = try await makeEnv(for: session)
                try checkLoad(requestID)
                tabularAgent = try TabularAgent.load(from: checkpointDir, env: algorithmEnv)
            case .dqn:
                let algorithmEnv = try await makeEnv(for: session)
                try checkLoad(requestID)
                let algorithm = try await DQN.load(
                    from: checkpointDir, env: algorithmEnv, includeBuffer: false)
                try checkLoad(requestID)
                dqnAlgorithm = algorithm
            case .ppo:
                let algorithmEnv = try await makeEnv(for: session)
                try checkLoad(requestID)
                let algorithm = try await PPO.load(from: checkpointDir, env: algorithmEnv)
                try checkLoad(requestID)
                ppoAlgorithm = algorithm
            case .sac:
                let algorithmEnv = try await makeEnv(for: session)
                try checkLoad(requestID)
                let algorithm = try await SAC.load(
                    from: checkpointDir, env: algorithmEnv, includeBuffer: false)
                try checkLoad(requestID)
                sacAlgorithm = algorithm
            case .td3:
                let algorithmEnv = try await makeEnv(for: session)
                try checkLoad(requestID)
                let algorithm = try await TD3.load(
                    from: checkpointDir, env: algorithmEnv, includeBuffer: false)
                try checkLoad(requestID)
                td3Algorithm = algorithm
            }

            loadedSession = session
            state.status = .idle
        } catch is CancellationError {
            if loadRequestID == requestID {
                env = nil
                state.status = .idle
            }
        } catch {
            guard loadRequestID == requestID else { return }
            env = nil
            state.status = .failed(error.localizedDescription)
        }
    }

    private func checkLoad(_ requestID: UUID) throws {
        try Task.checkCancellation()
        guard loadRequestID == requestID else { throw CancellationError() }
    }

    @MainActor
    func startEvaluation() {
        guard isEvaluationActive else { return }
        guard state.status != .running, state.status != .loading, evalTask == nil else { return }
        guard env != nil, loadedSession != nil else {
            state.status = .failed("No agent loaded")
            return
        }

        state.episodeRewards = []
        state.episodeLengths = []
        state.currentEpisode = 0
        state.status = .running

        evalTask = Task { [weak self] in
            await self?.runEvaluation()
        }
    }

    func stopEvaluation() {
        evalTask?.cancel()
        if state.status == .running {
            state.status = .idle
        }
    }

    func setEvaluationActive(_ active: Bool) {
        isEvaluationActive = active
        if !active { stopEvaluation() }
    }

    @MainActor
    private func runEvaluation() async {
        defer { evalTask = nil }
        guard let session = loadedSession else { return }

        let totalEpisodes = state.totalEpisodes
        let renderEnabled = state.renderEnabled
        let renderFPS = state.renderFPS

        var callbacks = EvaluateCallbacks(
            onStep: { @Sendable [weak self] in
                await MainActor.run { [weak self] in
                    self?.state.recordStep()
                }
                return !Task.isCancelled
            },
            onEpisodeEnd: { @Sendable [weak self] reward, length in
                await MainActor.run { [weak self] in
                    self?.state.recordEpisode(reward: reward, length: length)
                }
            }
        )

        if renderEnabled {
            callbacks.onSnapshot = { @Sendable [weak self] snapshot in
                await MainActor.run { [weak self] in
                    self?.renderSnapshot = snapshot
                    self?.state.renderVersion += 1
                }
                if renderFPS > 0 {
                    try? await Task.sleep(for: .seconds(1.0 / Double(renderFPS)))
                }
            }
        }

        do {
            if !renderEnabled, let valueEnv {
                try await runValueEvaluation(
                    session: session,
                    environment: valueEnv,
                    episodes: totalEpisodes
                )
            } else {
                try await runCompatibilityEvaluation(
                    session: session,
                    episodes: totalEpisodes,
                    callbacks: callbacks
                )
            }

            if !Task.isCancelled {
                state.status = .completed
            }
        } catch {
            if !Task.isCancelled {
                state.status = .failed(error.localizedDescription)
            }
        }
    }

    private func runCompatibilityEvaluation(
        session: SavedSession,
        episodes: Int,
        callbacks: EvaluateCallbacks
    ) async throws {
        switch session.algorithmType {
        case .qLearning, .sarsa:
            try await tabularAgent?.evaluate(
                episodes: episodes,
                callbacks: callbacks
            )
        case .dqn:
            try await dqnAlgorithm?.evaluate(
                episodes: episodes,
                callbacks: callbacks
            )
        case .ppo:
            try await ppoAlgorithm?.evaluate(
                episodes: episodes,
                callbacks: callbacks
            )
        case .sac:
            try await sacAlgorithm?.evaluate(
                episodes: episodes,
                callbacks: callbacks
            )
        case .td3:
            try await td3Algorithm?.evaluate(
                episodes: episodes,
                callbacks: callbacks
            )
        }
    }

    private func runValueEvaluation(
        session: SavedSession,
        environment: AnyValueEnvironment,
        episodes: Int
    ) async throws {
        let resetSeed = envResetSeed(settings: session.envSettings)
        let resetOptions = valueResetOptions(
            for: session.environmentID,
            settings: session.envSettings
        )
        for _ in 0..<episodes {
            try Task.checkCancellation()
            var observation = try await environment.reset(
                seed: resetSeed,
                options: resetOptions
            ).observation
            var reward = 0.0
            var length = 0
            var finished = false
            while !finished {
                try Task.checkCancellation()
                let action = try await valueAction(
                    for: observation,
                    algorithm: session.algorithmType
                )
                let step = try await environment.step(action)
                observation = step.observation
                reward += step.reward
                length += 1
                state.recordStep()
                finished = step.terminated || step.truncated
            }
            state.recordEpisode(reward: reward, length: length)
        }
    }

    private func valueAction(
        for observation: SpaceValue,
        algorithm: AlgorithmType
    ) async throws -> SpaceValue {
        switch algorithm {
        case .qLearning, .sarsa:
            guard let tabularAgent else {
                throw TrainError.invalidConfiguration("No tabular agent is loaded")
            }
            return try await tabularAgent.act(observation: observation).spaceValue
        case .dqn:
            guard let dqnAlgorithm else {
                throw TrainError.invalidConfiguration("No DQN agent is loaded")
            }
            return try await dqnAlgorithm.act(
                observation: tensorObservation(observation)
            ).spaceValue
        case .ppo:
            guard let ppoAlgorithm else {
                throw TrainError.invalidConfiguration("No PPO agent is loaded")
            }
            return try await ppoAlgorithm.act(
                observation: tensorObservation(observation)
            ).spaceValue
        case .sac:
            guard let sacAlgorithm else {
                throw TrainError.invalidConfiguration("No SAC agent is loaded")
            }
            return try await sacAlgorithm.act(
                observation: tensorObservation(observation)
            ).spaceValue
        case .td3:
            guard let td3Algorithm else {
                throw TrainError.invalidConfiguration("No TD3 agent is loaded")
            }
            return try await td3Algorithm.act(
                observation: tensorObservation(observation)
            ).spaceValue
        }
    }

    private func tensorObservation(_ observation: SpaceValue) throws -> TensorValue<Float> {
        switch observation {
        case .floatTensor(let value):
            return value
        case .continuous(let values, let shape):
            return try TensorValue(values, shape: shape)
        case .dictionary(let values) where loadedSession?.environmentID == MetroRunnerSettings.id:
            return try MetroRunnerObservation.flatten(values)
        default:
            throw TrainError.invalidConfiguration(
                "The loaded neural policy requires a float tensor observation"
            )
        }
    }

    func finishEvaluation() async {
        stopEvaluation()
        await clearAlgorithm()
    }

    private func clearAlgorithm() async {
        let previousEnvironment = valueEnv
        let previousTask = evalTask
        previousTask?.cancel()
        await previousTask?.value
        evalTask = nil
        valueEnv = nil
        tabularAgent = nil
        dqnAlgorithm = nil
        ppoAlgorithm = nil
        sacAlgorithm = nil
        td3Algorithm = nil
        loadedSession = nil
        renderSnapshot = nil
        await previousEnvironment?.close()
    }

    private func makeEnv(for session: SavedSession) async throws -> sending ConfiguredEnv {
        let envID = session.environmentID
        let settings = session.envSettings
        let options = try envOptions(for: envID, settings: settings)
        let maxSteps = frozenLakeMaxSteps(for: envID, settings: settings)
        var env = try await Gymnazo.make(
            envID,
            maxEpisodeSteps: maxSteps,
            options: options
        )
        env.renderMode = .human
        return ConfiguredEnv(
            base: env,
            resetSeed: envResetSeed(settings: settings),
            resetOptions: envResetOptions(for: envID, settings: settings)
        )
    }

    private func makeValueEnv(for session: SavedSession) async throws -> AnyValueEnvironment {
        let maxSteps = frozenLakeMaxSteps(
            for: session.environmentID,
            settings: session.envSettings
        )
        return try await Gymnazo.makeValue(
            session.environmentID,
            maxEpisodeSteps: maxSteps,
            options: try envOptions(
                for: session.environmentID,
                settings: session.envSettings
            )
        )
    }

    private func envOptions(for envID: String, settings: [String: SettingValue]) throws -> EnvOptions {
        if envID == MetroRunnerSettings.id {
            return ["config": try MetroRunnerSettings.config(from: settings)]
        }
        var options = EnvOptions()

        if envID.hasPrefix("FrozenLake") {
            let defaultSize = envID.contains("8x8") ? 8 : 4
            let size = settings["size"]?.intValue ?? defaultSize
            let isSlippery = settings["is_slippery"]?.boolValue ?? true
            let successRate = settings["success_rate"]?.floatValue ?? Float(1.0 / 3.0)
            let customMap =
                settings["custom_map"]?.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let generatedDesc = settings["_generated_desc"]?.stringValue ?? ""

            if !customMap.isEmpty {
                let rows =
                    customMap
                    .components(separatedBy: CharacterSet(charactersIn: ",\n"))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !rows.isEmpty {
                    options["desc"] = rows
                }
            } else if !generatedDesc.isEmpty {
                let rows = generatedDesc.components(separatedBy: ",").filter { !$0.isEmpty }
                if !rows.isEmpty {
                    options["desc"] = rows
                }
            } else if size == 4 {
                options["map_name"] = "4x4"
            } else if size == 8 {
                options["map_name"] = "8x8"
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
                "randomize",
                "obs_grayscale",
                "obs_resize",
                "obs_size",
                "obs_frame_stack",
                "obs_frame_skip",
                "obs_stack_size",
                "obs_replay_stack_compression",
                "obs_stack_padding",
            ]
            for (key, value) in settings {
                if resetKeys.contains(key) { continue }
                switch value {
                case .bool(let b): options[key] = b
                case .float(let f): options[key] = f
                case .string(let s): options[key] = s
                case .int(let i): options[key] = i
                }
            }
        }

        return options
    }

    private func frozenLakeMaxSteps(
        for envID: String, settings: [String: SettingValue]
    ) -> Int? {
        guard envID.hasPrefix("FrozenLake") else { return nil }
        let defaultSize = envID.contains("8x8") ? 8 : 4
        let size = settings["size"]?.intValue ?? defaultSize
        guard size != 4, size != 8 else { return nil }
        return size * 25
    }

    private func envResetOptions(
        for envID: String,
        settings: [String: SettingValue]
    ) -> EnvOptions {
        let baseName = envID.split(separator: "-").first.map(String.init) ?? envID
        var options = EnvOptions()

        if baseName == "Pendulum" {
            if let xInit = settings["x_init"]?.floatValue {
                options["x_init"] = xInit
            }
            if let yInit = settings["y_init"]?.floatValue {
                options["y_init"] = yInit
            }
        } else if baseName == "Acrobot" {
            if let low = settings["low"]?.floatValue {
                options["low"] = low
            }
            if let high = settings["high"]?.floatValue {
                options["high"] = high
            }
        } else if baseName == "CarRacing" || baseName == "CarRacingDiscrete" {
            if let randomize = settings["randomize"]?.boolValue {
                options["randomize"] = randomize
            }
        }

        return options
    }

    private func envResetSeed(settings: [String: SettingValue]) -> UInt64? {
        let seedValue =
            settings["seed"]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if seedValue.isEmpty { return nil }
        return UInt64(seedValue)
    }

    private func valueResetOptions(
        for envID: String,
        settings: [String: SettingValue]
    ) -> ValueResetOptions? {
        let options = envResetOptions(for: envID, settings: settings)
        var values: ValueResetOptions = [:]
        for (key, value) in options.storage {
            switch value {
            case let value as Bool:
                values[key] = .bool(value)
            case let value as Float:
                values[key] = .double(Double(value))
            case let value as Double:
                values[key] = .double(value)
            case let value as Int:
                values[key] = .discrete(value)
            case let value as String:
                values[key] = .text(value)
            default:
                continue
            }
        }
        return values.isEmpty ? nil : values
    }
}

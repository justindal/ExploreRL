import Foundation
import Gymnazo

@Observable
final class EvaluateViewModel {

    var sessions: [SavedSession] = []
    var state = EvaluationState()
    var env: (any Env)?
    var renderSnapshot: (any Sendable)?

    private var tabularAgent: TabularAgent?
    private var dqnAlgorithm: DQN?
    private var sacAlgorithm: SAC?
    private var loadedSession: SavedSession?
    private var evalTask: Task<Void, Never>?

    private let storage = SessionStorage.shared

    func loadSessions() {
        sessions = storage.listSessions()
    }

    @MainActor
    func loadSession(_ session: SavedSession) async {
        clearAlgorithm()
        state.reset()
        state.status = .loading
        env = nil
        renderSnapshot = nil

        do {
            let envID = session.environmentID
            let settings = session.envSettings
            let options = envOptions(for: envID, settings: settings)
            let maxSteps = frozenLakeMaxSteps(for: envID, settings: settings)
            var loadedEnv = try await Gymnazo.make(
                envID, maxEpisodeSteps: maxSteps, options: options
            )
            loadedEnv.renderMode = .human
            _ = try loadedEnv.reset()

            let checkpointDir = storage.checkpointDirectory(for: session.id)

            switch session.algorithmType {
            case .qLearning, .sarsa:
                tabularAgent = try TabularAgent.load(from: checkpointDir, env: loadedEnv)
            case .dqn:
                dqnAlgorithm = try DQN.load(from: checkpointDir, env: loadedEnv, includeBuffer: false)
            case .sac:
                sacAlgorithm = try SAC.load(from: checkpointDir, env: loadedEnv, includeBuffer: false)
            }

            env = loadedEnv
            loadedSession = session
            state.status = .idle
        } catch {
            state.status = .failed(error.localizedDescription)
        }
    }

    @MainActor
    func startEvaluation() {
        guard state.status != .running else { return }
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
        evalTask = nil
        if state.status == .running {
            state.status = .idle
        }
    }

    @MainActor
    private func runEvaluation() async {
        guard let session = loadedSession else { return }

        let totalEpisodes = state.totalEpisodes
        let renderEnabled = state.renderEnabled
        let renderFPS = state.renderFPS

        var callbacks = EvaluateCallbacks(
            onStep: { @Sendable in
                !Task.isCancelled
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
            switch session.algorithmType {
            case .qLearning, .sarsa:
                try await tabularAgent?.evaluate(
                    episodes: totalEpisodes,
                    callbacks: callbacks
                )
            case .dqn:
                try await dqnAlgorithm?.evaluate(
                    episodes: totalEpisodes,
                    callbacks: callbacks
                )
            case .sac:
                try await sacAlgorithm?.evaluate(
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

    private func clearAlgorithm() {
        evalTask?.cancel()
        evalTask = nil
        tabularAgent = nil
        dqnAlgorithm = nil
        sacAlgorithm = nil
        loadedSession = nil
        renderSnapshot = nil
    }

    private func envOptions(for envID: String, settings: [String: SettingValue]) -> EnvOptions {
        var options = EnvOptions()

        if envID.hasPrefix("FrozenLake") {
            let defaultSize = envID.contains("8x8") ? 8 : 4
            let size = settings["size"]?.intValue ?? defaultSize
            let isSlippery = settings["is_slippery"]?.boolValue ?? true
            let successRate = settings["success_rate"]?.floatValue ?? Float(1.0 / 3.0)
            let customMap = settings["custom_map"]?.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let generatedDesc = settings["_generated_desc"]?.stringValue ?? ""

            if !customMap.isEmpty {
                let rows = customMap
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
            let resetKeys: Set<String> = ["seed", "x_init", "y_init", "low", "high", "randomize"]
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
}

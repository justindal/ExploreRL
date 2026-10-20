import Foundation
import Gymnazo
import MLX
import Testing

@testable import ExploreRL

@Suite(.serialized)
struct MetroRunnerIntegrationTests {
    @Test
    @MainActor
    func metroRunLoadsWithDefaultsAndCompatibleAlgorithms() async throws {
        let id = MetroRunnerSettings.id
        let vm = TrainViewModel()
        await vm.loadEnv(id: id)
        let env = try #require(vm.env(for: id))
        #expect(env.spec?.displayName == "Metro Run")
        #expect(vm.availableAlgorithms(for: id, env: env) == [.dqn, .ppo])
        #expect(vm.trainingConfig(for: id).algorithm == .ppo)
        #expect(vm.trainingConfig(for: id).renderFPS == 15)
        #expect(env.observationSpace.shape == [1504])
        #expect(vm.envValueContracts[id]?.observation.flatDimension == 1504)
        guard case .other(let snapshot) = try env.render() else {
            Issue.record("Metro Run preview did not return a snapshot")
            return
        }
        #expect(snapshot is MetroRunnerSnapshot)
    }

    @Test
    @MainActor
    func metroRunSettingsControlTheSimulationAndSurviveEncoding() async throws {
        let vm = TrainViewModel()
        let id = MetroRunnerSettings.id
        vm.updateSetting(for: id, key: "curriculum", value: .string("barriers"))
        vm.updateSetting(for: id, key: "seed", value: .string("42"))
        vm.updateSetting(for: id, key: "frame_skip", value: .int(6))
        vm.updateSetting(for: id, key: "max_episode_seconds", value: .int(1))
        vm.updateSetting(for: id, key: "coin_weight", value: .float(0.25))
        let settings = vm.settings(for: id)
        let data = try JSONEncoder().encode(settings)
        let restored = try JSONDecoder().decode([String: SettingValue].self, from: data)
        #expect(restored == settings)
        let config = try MetroRunnerSettings.config(from: restored)
        #expect(config.curriculum == .barriers && config.frameSkip == 6)
        #expect(config.reward.coinWeight == 0.25)
        await vm.loadEnv(id: id)
        var env = try #require(vm.env(for: id))
        var result: Step?
        for _ in 0..<10 { result = try env.step(MLXArray(Int32(0))) }
        #expect(result?.truncated == true && result?.terminated == false)
        #expect(result?.info["physics_steps"]?.int == 60)
        #expect(result?.info["action_physics_steps"]?.int == 6)
        #expect(throws: TrainError.self) {
            try MetroRunnerSettings.config(from: ["curriculum": .string("unknown")])
        }
    }

    @Test
    @MainActor
    func metroRunTrainingResumesAndCheckpointEvaluatesWithAndWithoutRendering() async throws {
        let id = MetroRunnerSettings.id
        let vm = TrainViewModel()
        vm.updateSetting(for: id, key: "curriculum", value: .string("barriers"))
        vm.updateSetting(for: id, key: "max_episode_seconds", value: .int(1))
        vm.updateTrainingConfig(for: id) {
            $0.totalTimesteps = 10_000
            $0.renderFPS = 0
            $0.ppo.nSteps = 8
            $0.ppo.batchSize = 4
            $0.ppo.nEpochs = 1
            $0.ppo.netArch = [16]
        }
        await vm.loadEnv(id: id)
        vm.startTraining(for: id)
        defer { vm.setTrainingActive(false) }
        try await waitForProgress(vm, after: 16)
        await vm.pauseTraining(for: id)
        let policy = try #require(vm.ppoAlgorithms[id])
        let paused = vm.trainingState(for: id).currentTimestep
        #expect(vm.trainingState(for: id).status == .paused)
        #expect(vm.renderSnapshots[id] is MetroRunnerSnapshot)
        let before = await policy.nUpdates
        vm.startTraining(for: id)
        try await waitForProgress(vm, after: paused + 16)
        await vm.pauseTraining(for: id)
        #expect(vm.ppoAlgorithms[id] === policy)
        #expect(await policy.nUpdates > before)

        let session = SavedSession(id: UUID(), name: "Metro Run integration fixture",
            environmentID: id, algorithmType: .ppo, trainingConfig: vm.trainingConfig(for: id),
            trainingState: vm.trainingState(for: id), envSettings: vm.settings(for: id), savedAt: Date())
        let storage = SessionStorage.shared
        defer { try? storage.delete(sessionID: session.id) }
        try storage.save(session: session)
        try await policy.save(to: storage.checkpointDirectory(for: session.id))
        let restored = try #require(storage.listSessions().first { $0.id == session.id })
        #expect(restored.envSettings == session.envSettings)

        let loaded = TrainViewModel()
        try await loaded.loadSession(restored)
        #expect(loaded.ppoAlgorithms[id] != nil)
        #expect(loaded.trainingState(for: id).currentTimestep == session.trainingState.currentTimestep)
        await loaded.resetTraining(for: id)

        let evaluation = EvaluateViewModel()
        await evaluation.loadSession(restored)
        #expect(evaluation.state.status == .idle)
        for renderEnabled in [false, true] {
            evaluation.state.totalEpisodes = 1
            evaluation.state.renderEnabled = renderEnabled
            evaluation.state.renderFPS = 0
            evaluation.startEvaluation()
            let deadline = ContinuousClock.now.advanced(by: .seconds(20))
            while evaluation.state.status == .running && ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(20))
            }
            #expect(evaluation.state.status == .completed)
            #expect(evaluation.state.episodeLengths == [15])
            if renderEnabled { #expect(evaluation.renderSnapshot is MetroRunnerSnapshot) }
            evaluation.stopEvaluation()
        }
        await vm.resetTraining(for: id)
        #expect(vm.trainingState(for: id).status == .idle)
        #expect(vm.ppoAlgorithms[id] == nil)
    }

    @MainActor
    private func waitForProgress(_ vm: TrainViewModel, after timestep: Int) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(20))
        while vm.trainingState(for: MetroRunnerSettings.id).currentTimestep <= timestep {
            if vm.trainingState(for: MetroRunnerSettings.id).isFailed || ContinuousClock.now >= deadline {
                await vm.pauseTraining(for: MetroRunnerSettings.id)
                Issue.record("Metro Run training failed to advance: \(vm.trainingState(for: MetroRunnerSettings.id).status)")
                throw CancellationError()
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}

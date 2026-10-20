import Foundation
import Gymnazo
import MLX
import Testing

@testable import ExploreRL

@Suite(.serialized)
struct TrainingContinuationTests {
    @Test @MainActor
    func completedAndSavedRunsContinueFromTheirExistingStepCounters() async throws {
        let vm = await fixture(.ppo)
        try await finish(vm, id: "CartPole")
        let initial = vm.trainingState(for: "CartPole")
        #expect(initial.entropyCoefHistory.last != nil)
        let policy = try #require(vm.ppoAlgorithms["CartPole"])
        try vm.extendTraining(for: "CartPole", additionalTimesteps: 8)
        try await finish(vm, id: "CartPole")
        #expect(vm.trainingState(for: "CartPole").currentTimestep == 16)
        #expect(vm.ppoAlgorithms["CartPole"] === policy)
        #expect(vm.trainingState(for: "CartPole").lossHistory.starts(with: initial.lossHistory))

        let snapshot = try await vm.makeSnapshot(for: "CartPole")
        defer { SessionStorage.shared.discard(snapshot) }
        let saved = try SessionStorage.shared.saveSnapshot(snapshot, name: "Continuation fixture")
        defer { try? SessionStorage.shared.delete(sessionID: saved.id) }
        let restored = TrainViewModel()
        try await restored.loadSession(saved)
        #expect(restored.trainingState(for: "CartPole").status == .completed)
        try restored.extendTraining(for: "CartPole", additionalTimesteps: 8)
        #expect(restored.trainingState(for: "CartPole").currentTimestep == 16)
        try await finish(restored, id: "CartPole")
        #expect(restored.trainingState(for: "CartPole").currentTimestep == 24)
        #expect(saved.trainingState.currentTimestep == 16)
        #expect(restored.activeTrainingElapsed(for: "CartPole") >= (saved.activeTrainingSeconds ?? 0))
    }

    @Test @MainActor
    func compatibleTuningPreservesWeightsCountersAndAppliesNewPPOSettings() async throws {
        let vm = await fixture(.ppo)
        try await finish(vm, id: "CartPole")
        let before = try await vm.makeSnapshot(for: "CartPole")
        defer { SessionStorage.shared.discard(before) }
        var config = vm.trainingConfig(for: "CartPole")
        config.ppo.learningRate = 1e-4
        config.ppo.gamma = 0.98
        config.ppo.nSteps = 4
        config.ppo.batchSize = 2
        try await vm.applyContinuationConfig(config, for: "CartPole")
        #expect(vm.ppoAlgorithms["CartPole"]?.config.gamma == 0.98)
        #expect(vm.ppoAlgorithms["CartPole"]?.config.nSteps == 4)
        #expect(await vm.ppoAlgorithms["CartPole"]?.numTimesteps == 8)
        let after = try await vm.makeSnapshot(for: "CartPole")
        defer { SessionStorage.shared.discard(after) }
        let oldWeights = try MLX.loadArrays(url: before.checkpointDirectory.appendingPathComponent("policy.safetensors"))
        let newWeights = try MLX.loadArrays(url: after.checkpointDirectory.appendingPathComponent("policy.safetensors"))
        #expect(oldWeights.keys.sorted() == newWeights.keys.sorted())
        for key in oldWeights.keys {
            #expect(oldWeights[key]?.asArray(Float.self) == newWeights[key]?.asArray(Float.self))
        }
        let json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf:
            after.checkpointDirectory.appendingPathComponent("metadata.json"))) as? [String: Any])
        #expect(json["numTimesteps"] as? Int == 8)
        try vm.extendTraining(for: "CartPole", additionalTimesteps: 8)
        try await finish(vm, id: "CartPole")
        #expect(vm.trainingState(for: "CartPole").currentTimestep == 16)
    }

    @Test @MainActor
    func supportedTuningAndContinuationWorkForEveryOtherAlgorithm() async throws {
        for algorithm in [AlgorithmType.qLearning, .sarsa, .dqn, .sac, .td3] {
            let vm = await fixture(algorithm)
            let id = environment(for: algorithm)
            try await finish(vm, id: id)
            var config = vm.trainingConfig(for: id)
            switch algorithm {
            case .qLearning, .sarsa: config.tabular.gamma = 0.9
            case .dqn: config.dqn.gamma = 0.9
            case .sac: config.sac.gamma = 0.9
            case .td3: config.td3.gamma = 0.9
            case .ppo: break
            }
            try await vm.applyContinuationConfig(config, for: id)
            switch algorithm {
            case .qLearning, .sarsa: #expect(await vm.tabularAgents[id]?.config.gamma == 0.9)
            case .dqn: #expect(vm.dqnAlgorithms[id]?.config.gamma == 0.9)
            case .sac: #expect(vm.sacAlgorithms[id]?.offPolicyConfig.gamma == 0.9)
            case .td3: #expect(vm.td3Algorithms[id]?.offPolicyConfig.gamma == 0.9)
            case .ppo: break
            }
            try vm.extendTraining(for: id, additionalTimesteps: 8)
            try await finish(vm, id: id)
            #expect(vm.trainingState(for: id).currentTimestep == 16)
        }
    }

    @Test @MainActor
    func temporaryEvaluationIsExcludedFromLibraryAndPromotionIsIndependent() async throws {
        let vm = await fixture(.ppo)
        try await finish(vm, id: "CartPole")
        let flow = TrainingEvaluationViewModel()
        await flow.prepare(using: vm, id: "CartPole")
        let snapshot = try #require(flow.snapshot)
        defer { SessionStorage.shared.discard(snapshot) }
        #expect(!SessionStorage.shared.listSessions().contains { $0.id == snapshot.id })
        await flow.confirm()
        #expect(flow.isConfirmed)
        let evaluation = flow.evaluation
        await evaluation.loadSession(snapshot.session, checkpointDirectory: snapshot.checkpointDirectory)
        #expect(evaluation.env != nil)
        evaluation.setEvaluationActive(false)
        evaluation.startEvaluation()
        #expect(evaluation.state.status == .idle)
        evaluation.setEvaluationActive(true)
        evaluation.state.renderEnabled = false
        evaluation.state.totalEpisodes = 1
        evaluation.startEvaluation()
        let deadline = ContinuousClock.now.advanced(by: .seconds(15))
        while evaluation.state.status == .running, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(evaluation.state.status == .completed)
        await evaluation.finishEvaluation()
        #expect(vm.trainingState(for: "CartPole").currentTimestep == 8)
        let saved = try SessionStorage.shared.saveSnapshot(snapshot, name: "Snapshot fixture")
        defer { try? SessionStorage.shared.delete(sessionID: saved.id) }
        SessionStorage.shared.discard(snapshot)
        #expect(FileManager.default.fileExists(atPath: SessionStorage.shared.checkpointDirectory(for: saved.id).path))
        #expect(SessionStorage.shared.listSessions().contains { $0.id == saved.id })
        await flow.close()
        #expect(flow.snapshot == nil)
    }

    @Test @MainActor
    func unsafeEditsAreRejectedWithoutReplacingTheModel() async throws {
        let vm = await fixture(.ppo)
        try await finish(vm, id: "CartPole")
        let policy = vm.ppoAlgorithms["CartPole"]
        var config = vm.trainingConfig(for: "CartPole")
        config.ppo.netArch = [32]
        await #expect(throws: TrainError.self) { try await vm.applyContinuationConfig(config, for: "CartPole") }
        #expect(vm.ppoAlgorithms["CartPole"] === policy)
        #expect(throws: TrainError.self) { try vm.extendTraining(for: "CartPole", additionalTimesteps: 0) }
    }

    @Test @MainActor
    func timingUsesMeasuredStepsAndRepeatedPauseDoesNotAddElapsedTime() {
        let start = Date(timeIntervalSince1970: 100)
        var timing = TrainingTiming(startedAt: start, initialTimestep: 100, previousElapsed: 60)
        timing.pause(at: start.addingTimeInterval(10))
        timing.pause(at: start.addingTimeInterval(20))
        #expect(timing.activeElapsed(now: start.addingTimeInterval(100)) == 70)
        timing.resume(at: start.addingTimeInterval(100))
        #expect(timing.activeElapsed(now: start.addingTimeInterval(110)) == 80)
        let vm = TrainViewModel()
        vm.trainingTimings["legacy"] = timing
        vm.updateTrainingState(for: "legacy") { $0.currentTimestep = 120 }
        #expect(vm.timedTrainingSteps(for: "legacy") == 20)
        #expect(stepsPerMin(timesteps: 20, elapsed: 60) == 20)
        #expect(etaSeconds(stepsPerMinute: .nan, currentTimestep: 100, totalTimesteps: 200) == nil)
        #expect(formatTime(.infinity) == "—")
    }

    @Test @MainActor
    func systemCheckUsesLiveMLXMemoryAndVerifiesComputation() async {
        let vm = SettingsViewModel()
        vm.loadDeviceInfo()
        #expect(vm.deviceInfo.appFootprintBytes.map { $0 > 0 } == true)
        #expect(vm.deviceInfo.sampledAt != nil)
        #expect(vm.deviceInfo.mlxPeakBytes ?? 0 >= vm.deviceInfo.mlxActiveBytes ?? 0)
        #expect(!vm.readinessChecks.contains { $0.title == "GPU Working Set" })
        await vm.verifyCompute()
        #expect(vm.computeResult?.hasPrefix("Passed:") == true)
        #expect(!vm.isCheckingCompute)
    }

    @MainActor private func fixture(_ algorithm: AlgorithmType) async -> TrainViewModel {
        let vm = TrainViewModel()
        let id = environment(for: algorithm)
        vm.updateTrainingConfig(for: id) {
            $0.algorithm = algorithm; $0.totalTimesteps = 8; $0.renderDuringTraining = false
            $0.ppo.nSteps = 8; $0.ppo.batchSize = 4; $0.ppo.nEpochs = 1; $0.ppo.netArch = [8]
            $0.dqn.bufferSize = 64; $0.dqn.batchSize = 4; $0.dqn.learningStarts = 0; $0.dqn.netArch = [8]
            $0.sac.bufferSize = 64; $0.sac.batchSize = 4; $0.sac.learningStarts = 0; $0.sac.netArch = [8]; $0.sac.criticNetArch = [8]
            $0.td3.bufferSize = 64; $0.td3.batchSize = 4; $0.td3.learningStarts = 0; $0.td3.netArch = [8]
        }
        await vm.loadEnv(id: id)
        vm.startTraining(for: id)
        return vm
    }

    private func environment(for algorithm: AlgorithmType) -> String {
        switch algorithm {
        case .qLearning, .sarsa: "FrozenLake"
        case .sac, .td3: "Pendulum"
        case .dqn, .ppo: "CartPole"
        }
    }

    @MainActor private func finish(_ vm: TrainViewModel, id: String) async throws {
        let task = try #require(vm.trainingTasks[id])
        await task.value
        #expect(vm.trainingState(for: id).status == .completed)
        #expect(vm.trainingTasks[id] == nil)
    }
}

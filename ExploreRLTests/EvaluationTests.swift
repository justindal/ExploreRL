import Gymnazo
import MLX
import Testing

@testable import ExploreRL

@Suite(.serialized)
struct EvaluationTests {
    @Test @MainActor
    func singleEnvironmentActionsPreserveShapeAndBoundsValidation() async throws {
        for shape in [[1], [1, 1]] {
            var environment = ConfiguredEnv(
                base: try await Gymnazo.make("MountainCarContinuous"),
                resetSeed: 42,
                resetOptions: [:]
            )
            _ = try environment.reset(seed: nil, options: nil)
            let step = try environment.step(MLXArray([Float(0.5)], shape))
            #expect(abs(step.reward + 0.025) < 1e-6)
        }
        for (values, shape) in [([Float(0), 0], [2, 1]), ([Float(2)], [1, 1])] {
            var environment = ConfiguredEnv(
                base: try await Gymnazo.make("MountainCarContinuous"),
                resetSeed: 42,
                resetOptions: [:]
            )
            _ = try environment.reset(seed: nil, options: nil)
            #expect(throws: GymnazoError.self) {
                try environment.step(MLXArray(values, shape))
            }
        }
    }

    @Test(arguments: [AlgorithmType.sac, .ppo, .td3]) @MainActor
    func pausedHeadlessContinuousTrainingSupportsRenderedEvaluation(
        algorithm: AlgorithmType
    ) async throws {
        let id = "MountainCarContinuous"
        let training = TrainViewModel()
        training.updateTrainingConfig(for: id) {
            $0.algorithm = algorithm
            $0.totalTimesteps = 100_000
            $0.renderDuringTraining = false
            $0.ppo.nSteps = 8
            $0.ppo.batchSize = 4
            $0.ppo.nEpochs = 1
            $0.ppo.netArch = [8]
            $0.sac.bufferSize = 64
            $0.sac.batchSize = 4
            $0.sac.learningStarts = 0
            $0.sac.trainFrequency = 1
            $0.sac.gradientSteps = 1
            $0.sac.netArch = [8]
            $0.sac.criticNetArch = [8]
            $0.td3.bufferSize = 64
            $0.td3.batchSize = 4
            $0.td3.learningStarts = 0
            $0.td3.netArch = [8]
        }
        await training.loadEnv(id: id)
        training.startTraining(for: id)
        let trainingDeadline = ContinuousClock.now.advanced(by: .seconds(15))
        while training.trainingState(for: id).status == .training,
            training.trainingState(for: id).currentTimestep < 8,
            ContinuousClock.now < trainingDeadline
        {
            try await Task.sleep(for: .milliseconds(10))
        }
        await training.pauseTraining(for: id)
        #expect(training.trainingState(for: id).status == .paused)
        #expect(training.trainingState(for: id).currentTimestep >= 8)
        let pausedSteps = training.trainingState(for: id).currentTimestep
        let snapshot = try await training.makeSnapshot(for: id)
        defer { SessionStorage.shared.discard(snapshot) }

        for renderEnabled in [false, true] {
            let evaluation = EvaluateViewModel()
            await evaluation.loadSession(
                snapshot.session,
                checkpointDirectory: snapshot.checkpointDirectory
            )
            #expect(evaluation.state.status == .idle)
            evaluation.state.totalEpisodes = 1
            evaluation.state.renderFPS = 0
            evaluation.state.renderEnabled = renderEnabled
            evaluation.startEvaluation()
            let deadline = ContinuousClock.now.advanced(by: .seconds(15))
            while evaluation.state.status == .running, ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(10))
            }
            #expect(evaluation.state.status == .completed)
            #expect(evaluation.state.episodeLengths.count == 1)
            if renderEnabled {
                #expect(evaluation.renderSnapshot is MountainCarSnapshot)
                #expect(evaluation.state.renderVersion > 0)
            }
            await evaluation.finishEvaluation()
        }
        #expect(training.trainingState(for: id).status == .paused)
        #expect(training.trainingState(for: id).currentTimestep == pausedSteps)
    }
}

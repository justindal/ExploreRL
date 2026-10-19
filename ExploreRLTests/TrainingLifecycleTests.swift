import Foundation
import Testing

@testable import ExploreRL

@Suite(.serialized)
struct TrainingLifecycleTests {
    @Test
    @MainActor
    func inactiveAppPreventsStartingTraining() {
        let vm = TrainViewModel()
        vm.setTrainingActive(false)
        vm.startTraining(for: "CartPole")

        #expect(!vm.trainingPolicy(for: "CartPole").isAllowed)
        #expect(vm.trainingTasks.isEmpty)
        #expect(vm.trainingState(for: "CartPole").status == .idle)

        vm.setTrainingActive(true)
        #expect(vm.trainingPolicy(for: "CartPole").isAllowed)
        #expect(vm.trainingTasks.isEmpty)
    }

    @Test
    @MainActor
    func becomingInactiveCancelsEveryRunWithoutClearingProgress() async {
        let vm = TrainViewModel()
        for id in ["CartPole", "FlappyBird"] {
            vm.updateTrainingState(for: id) {
                $0.status = .training
                $0.currentTimestep = 42
            }
            vm.trainingTasks[id] = Task {
                try? await Task.sleep(for: .seconds(60))
            }
        }
        let tasks = Array(vm.trainingTasks.values)

        vm.setTrainingActive(false)
        #expect(tasks.allSatisfy { $0.isCancelled })
        for task in tasks {
            await task.value
        }
        for id in ["CartPole", "FlappyBird"] {
            #expect(vm.trainingState(for: id).status == .paused)
            #expect(vm.trainingState(for: id).currentTimestep == 42)
        }
        vm.setTrainingActive(true)
        #expect(!vm.trainingPolicy(for: "CartPole").isAllowed)
    }

    @Test
    @MainActor
    func cancellationBeforeStartupLeavesTrainingPaused() async throws {
        let vm = TrainViewModel()
        await vm.loadEnv(id: "CartPole")
        vm.startTraining(for: "CartPole")
        let task = try #require(vm.trainingTasks["CartPole"])

        vm.setTrainingActive(false)
        await task.value

        #expect(vm.trainingState(for: "CartPole").status == .paused)
        #expect(vm.trainingState(for: "CartPole").currentTimestep == 0)
        #expect(vm.dqnAlgorithms.isEmpty)
        #expect(vm.trainingTasks.isEmpty)
        #expect(vm.flushTasks.isEmpty)
    }

    @Test
    @MainActor
    func gpuTrainingPausesAndResumesWithTheSameModel() async throws {
        let id = "CartPole"
        let vm = TrainViewModel()
        vm.updateTrainingConfig(for: id) {
            $0.algorithm = .dqn
            $0.totalTimesteps = 100_000
            $0.renderDuringTraining = false
            $0.dqn.learningStarts = 4
            $0.dqn.bufferSize = 128
            $0.dqn.batchSize = 4
            $0.dqn.netArch = [16, 16]
        }
        await vm.loadEnv(id: id)
        vm.startTraining(for: id)
        try await waitForProgress(vm, id: id, after: 4)
        let model = try #require(vm.dqnAlgorithms[id])
        let task = try #require(vm.trainingTasks[id])

        vm.setTrainingActive(false)
        await task.value
        let pausedStep = vm.trainingState(for: id).currentTimestep
        #expect(vm.trainingState(for: id).status == .paused)
        #expect(vm.trainingTasks.isEmpty)
        #expect(vm.flushTasks.isEmpty)
        #expect(pausedStep > 4)

        vm.setTrainingActive(true)
        #expect(vm.trainingTasks.isEmpty)
        #expect(vm.trainingState(for: id).status == .paused)

        vm.startTraining(for: id)
        try await waitForProgress(vm, id: id, after: pausedStep)
        #expect(vm.dqnAlgorithms[id] === model)
        await vm.pauseTraining(for: id)
        #expect(vm.trainingState(for: id).status == .paused)
        #expect(vm.trainingState(for: id).currentTimestep > pausedStep)

        await vm.resetTraining(for: id)
        #expect(vm.trainingState(for: id).status == .idle)
        #expect(vm.trainingState(for: id).currentTimestep == 0)
    }

    @MainActor
    private func waitForProgress(_ vm: TrainViewModel, id: String, after timestep: Int) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(20))
        while vm.trainingState(for: id).currentTimestep <= timestep {
            if vm.trainingState(for: id).isFailed || ContinuousClock.now >= deadline {
                vm.setTrainingActive(false)
                let task = vm.trainingTasks[id]
                await task?.value
                Issue.record("Training did not advance beyond step \(timestep)")
                throw CancellationError()
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}

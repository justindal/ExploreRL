import Testing

@testable import ExploreRL

struct TypedBoundaryTests {
    @Test
    @MainActor
    func representativeEnvironmentContractsLoad() async throws {
        let discrete = try await EnvValueContract.load(id: "CartPole", options: [:])
        let continuous = try await EnvValueContract.load(id: "Pendulum", options: [:])
        let image = try await EnvValueContract.load(id: "CarRacing", options: [:])
        let tuple = try await EnvValueContract.load(id: "Blackjack", options: [:])
        let flappyBird = try await EnvValueContract.load(id: "FlappyBird", options: [:])
        let snake = try await EnvValueContract.load(id: "Snake", options: [:])
        let twentyFortyEight = try await EnvValueContract.load(id: "2048", options: [:])

        #expect(discrete.action.kind.isDiscrete)
        #expect(continuous.action.kind.isContinuous)
        #expect(image.observation.flatDimension == 96 * 96 * 3)
        #expect(tuple.observation.kind.isTabular)
        #expect(flappyBird.observation.flatDimension == 4)
        #expect(flappyBird.action.kind.isDiscrete)
        #expect(snake.observation.flatDimension == 148)
        #expect(snake.action.kind.isDiscrete)
        #expect(twentyFortyEight.observation.flatDimension == 16)
        #expect(twentyFortyEight.action.kind.isDiscrete)
    }

    @Test
    func accumulatorDrainsConcurrentValues() async {
        let accumulator = TrainingAccumulator()
        await withTaskGroup(of: Void.self) { group in
            for timestep in 0..<100 {
                group.addTask {
                    accumulator.recordStep(timestep: timestep, explorationRate: 0.5)
                    accumulator.recordEpisode(reward: Double(timestep), length: timestep + 1)
                }
            }
        }

        let pending = accumulator.drain()
        #expect(pending.episodes.count == 100)
        #expect(pending.explorationRate == 0.5)
        #expect(accumulator.drain().episodes.isEmpty)
    }
}

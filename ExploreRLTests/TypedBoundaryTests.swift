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

        #expect(discrete.action.kind.isDiscrete)
        #expect(continuous.action.kind.isContinuous)
        #expect(image.observation.flatDimension == 96 * 96 * 3)
        #expect(tuple.observation.kind.isTabular)
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

import Foundation
import Testing

@testable import ExploreRL

@Suite(.serialized)
struct WorkspaceNavigationTests {
    @Test
    @MainActor
    func ipadSidebarSelectionKeepsTheCompactTrainingDestination() {
        var navigation = TrainNavigation()
        navigation.selectedEnvironmentID = "MetroRunner-v0"
        let destination = IPadDestination(tab: .train, environmentID: navigation.selectedEnvironmentID)
        #expect(destination == .environment("MetroRunner-v0"))
        #expect(destination.tab == .train)
        #expect(navigation.path == ["MetroRunner-v0"])
        #expect(IPadDestination(tab: .library, environmentID: navigation.selectedEnvironmentID) == .tab(.library))
        #expect(IPadDestination(tab: .train, environmentID: nil) == .tab(.train))
        #expect(AppTab(rawValue: "Train") == .train)
        #expect(AppTab(rawValue: "Evaluate") == .evaluate)
        #expect(AppTab(rawValue: "Home") == .home)
        #expect(IPadDestination(tab: .home, environmentID: navigation.selectedEnvironmentID) == .tab(.home))
    }

    @Test
    @MainActor
    func invalidSettingDraftBlocksOnlyItsEnvironment() {
        let vm = TrainViewModel()
        vm.invalidSettingsEnvs.insert("MetroRunner-v0")
        vm.startTraining(for: "MetroRunner-v0")
        #expect(!vm.trainingPolicy(for: "MetroRunner-v0").isAllowed)
        #expect(vm.trainingTasks.isEmpty)
        #expect(vm.trainingPolicy(for: "CartPole").isAllowed)
        vm.invalidSettingsEnvs.remove("MetroRunner-v0")
        #expect(vm.trainingPolicy(for: "MetroRunner-v0").isAllowed)
    }

    @Test
    @MainActor
    func cancelledAgentLoadDoesNotLeaveTheScreenLoading() async {
        let vm = EvaluateViewModel()
        let session = SavedSession(
            id: UUID(), name: "Unavailable agent", environmentID: "MissingEnvironment",
            algorithmType: .dqn, trainingConfig: TrainingConfig(),
            trainingState: TrainingState(), envSettings: [:], savedAt: Date()
        )
        let task = Task { await vm.loadSession(session) }
        task.cancel()
        await task.value
        #expect(vm.state.status == .idle)
        #expect(vm.env == nil)
    }

    @Test
    @MainActor
    func failedAgentLoadCanBeRetriedWithoutShowingAReadyEnvironment() async {
        let vm = EvaluateViewModel()
        let session = SavedSession(
            id: UUID(), name: "Unavailable agent", environmentID: "MissingEnvironment",
            algorithmType: .dqn, trainingConfig: TrainingConfig(),
            trainingState: TrainingState(), envSettings: [:], savedAt: Date()
        )
        for _ in 0..<2 {
            await vm.loadSession(session)
            #expect(vm.state.status.errorMessage != nil)
            #expect(vm.env == nil)
        }
    }

    @Test
    @MainActor
    func trainingSelectionSurvivesCompactAndSplitNavigation() {
        var navigation = TrainNavigation()
        navigation.path = ["MetroRunner-v0"]
        #expect(navigation.selectedEnvironmentID == "MetroRunner-v0")
        navigation.selectedEnvironmentID = "CartPole"
        #expect(navigation.path == ["CartPole"])
        navigation.path.removeAll()
        #expect(navigation.selectedEnvironmentID == nil)
    }

    @Test
    @MainActor
    func partialEvaluationDoesNotReportSuccess() {
        var state = EvaluationState()
        state.status = .running
        state.recordEpisode(reward: 12, length: 30)
        #expect(state.status.summaryTitle == "Evaluation in progress")
        #expect(state.status.summarySymbol != "checkmark.circle.fill")

        state.status = .failed("Checkpoint unavailable")
        #expect(state.status.summaryTitle == "Partial results")
        #expect(state.status.errorMessage == "Checkpoint unavailable")
        #expect(state.status.summarySymbol != "checkmark.circle.fill")

        state.status = .idle
        #expect(state.status.summaryTitle == "Partial results")
        state.status = .completed
        #expect(state.status.summarySymbol == "checkmark.circle.fill")
        #expect(state.status.errorMessage == nil)
    }
}

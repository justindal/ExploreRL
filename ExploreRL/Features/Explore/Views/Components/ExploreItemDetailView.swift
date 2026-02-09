import SwiftUI

struct ExploreItemDetailView: View {
    let item: ExploreItem

    var body: some View {
        switch item {
        case .rlLoop: RLLoopPage()
        case .returns: ReturnsPage()
        case .exploration: ExplorationPage()
        case .replay: ReplayPage()
        case .neuralNetworks: NeuralNetworksPage()
        case .activationFunctions: ActivationFunctionsPage()
        case .optimizers: OptimizersPage()
        case .qLearning: QLearningPage()
        case .sarsa: SARSAPage()
        case .dqn: DQNPage()
        case .sac: SACPage()
        case .frozenLake: FrozenLakePage()
        case .blackjack: BlackjackPage()
        case .taxi: TaxiPage()
        case .cliffWalking: CliffWalkingPage()
        case .cartPole: CartPolePage()
        case .mountainCar: MountainCarPage()
        case .acrobot: AcrobotPage()
        case .pendulum: PendulumPage()
        case .lunarLander: LunarLanderPage()
        case .carRacing: CarRacingPage()
        }
    }
}

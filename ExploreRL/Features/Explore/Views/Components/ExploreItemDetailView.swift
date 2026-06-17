import SwiftUI

struct ExploreItemDetailView: View {
    let item: ExploreItem

    var body: some View {
        switch item {
        case .rlLoop: RLLoopPage()
        case .multiArmedBandits: MultiArmedBanditsPage(relatedItems: item.relatedItems)
        case .returns: ReturnsPage()
        case .dynamicProgramming: DynamicProgrammingPage(relatedItems: item.relatedItems)
        case .monteCarlo: MonteCarloPage(relatedItems: item.relatedItems)
        case .exploration: ExplorationPage()
        case .replay: ReplayPage()
        case .neuralNetworks: NeuralNetworksPage()
        case .activationFunctions: ActivationFunctionsPage()
        case .optimizers: OptimizersPage()
        case .qLearning: QLearningPage(relatedItems: item.relatedItems)
        case .sarsa: SARSAPage(relatedItems: item.relatedItems)
        case .policyGradient: PolicyGradientPage(relatedItems: item.relatedItems)
        case .dqn: DQNPage(relatedItems: item.relatedItems)
        case .ddpg: DDPGPage(relatedItems: item.relatedItems)
        case .ppo: PPOPage(relatedItems: item.relatedItems)
        case .sac: SACPage(relatedItems: item.relatedItems)
        case .td3: TD3Page(relatedItems: item.relatedItems)
        case .a2c: A2CPage(relatedItems: item.relatedItems)
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

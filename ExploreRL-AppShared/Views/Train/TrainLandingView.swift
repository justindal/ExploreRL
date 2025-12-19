//
//  TrainLandingView.swift
//

import SwiftUI

struct TrainLandingView: View {
    var trainingState = TrainingState.shared
    
    var frozenLakeRunner: FrozenLakeRunner
    var blackjackRunner: BlackjackRunner
    var taxiRunner: TaxiRunner
    var cartPoleRunner: CartPoleRunner
    var mountainCarRunner: MountainCarRunner
    var mountainCarContinuousRunner: MountainCarContinuousRunner
    var acrobotRunner: AcrobotRunner
    var pendulumRunner: PendulumRunner
    var lunarLanderRunner: LunarLanderRunner
    var lunarLanderContinuousRunner: LunarLanderContinuousRunner
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(EnvironmentRegistry.groupedEnvironments, id: \.category) { group in
                    Section(group.category.rawValue) {
                        ForEach(group.environments) { envInfo in
                            NavigationLink {
                                trainDestination(for: envInfo.type)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: envInfo.icon)
                                        .font(.title3)
                                        .foregroundStyle(envInfo.accentColor)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(envInfo.displayName)
                                                .font(.body)
                                            
                                            if trainingState.activeEnvironment == envInfo.displayName {
                                                ProgressView()
                                                    .controlSize(.mini)
                                            }
                                        }
                                        
                                        Text(envInfo.algorithmName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Train")
        }
    }
    
    @ViewBuilder
    private func trainDestination(for type: EnvironmentType) -> some View {
        switch type {
        case .frozenLake:
            FrozenLakeView(runner: frozenLakeRunner)
                .navigationTitle("Frozen Lake")
        case .blackjack:
            BlackjackView(runner: blackjackRunner)
                .navigationTitle("Blackjack")
        case .taxi:
            TaxiView(runner: taxiRunner)
                .navigationTitle("Taxi")
        case .cartPole:
            CartPoleView(runner: cartPoleRunner)
                .navigationTitle("Cart Pole")
        case .mountainCar:
            MountainCarView(runner: mountainCarRunner)
                .navigationTitle("Mountain Car")
        case .mountainCarContinuous:
            MountainCarContinuousView(runner: mountainCarContinuousRunner)
                .navigationTitle("Mountain Car Continuous")
        case .acrobot:
            AcrobotView(runner: acrobotRunner)
                .navigationTitle("Acrobot")
        case .pendulum:
            PendulumView(runner: pendulumRunner)
                .navigationTitle("Pendulum")
        case .lunarLander:
            LunarLanderView(runner: lunarLanderRunner)
                .navigationTitle("Lunar Lander")
        case .lunarLanderContinuous:
            LunarLanderContinuousView(runner: lunarLanderContinuousRunner)
                .navigationTitle("Lunar Lander Continuous")
        }
    }
}


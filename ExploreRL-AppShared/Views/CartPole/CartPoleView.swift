//
//  CartPoleView.swift
//

import SwiftUI
import Gymnazo

struct CartPoleView: View {
    @Bindable var runner: CartPoleRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Cart Pole",
            environmentType: .cartPole,
            algorithmType: "DQN",
            accentColor: .blue,
            canvasAspectRatio: 1.5,
            canvasMaxSize: CGSize(width: 600, height: 400),
            canvas: { snapshot in
                if let snapshot {
                    CartPoleViewAdapter(snapshot: snapshot)
                }
            },
            configuration: {
                CartPoleConfigurationView(runner: runner)
            },
            charts: { columns in
                CartPoleChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.cartPole(maxStepsPerEpisode: runner.maxStepsPerEpisode)
                )
            }
        )
    }
}

struct CartPoleViewAdapter: View {
    let snapshot: CartPoleSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.CartPoleView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}

#Preview {
    CartPoleView(runner: CartPoleRunner())
}

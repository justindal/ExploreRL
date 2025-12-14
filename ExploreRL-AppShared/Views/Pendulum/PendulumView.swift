//
//  PendulumView.swift
//

import SwiftUI
import Gymnazo

struct PendulumView: View {
    @Bindable var runner: PendulumRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Pendulum",
            environmentType: .pendulum,
            algorithmType: "SAC",
            accentColor: .indigo,
            canvasAspectRatio: 1.0,
            canvasMaxSize: CGSize(width: 400, height: 400),
            canvas: { snapshot in
                if let snapshot {
                    PendulumViewAdapter(snapshot: snapshot)
                }
            },
            configuration: {
                PendulumConfigurationView(runner: runner)
            },
            charts: { columns in
                PendulumChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.pendulum(maxStepsPerEpisode: runner.maxStepsPerEpisode)
                )
            }
        )
    }
}

struct PendulumViewAdapter: View {
    let snapshot: PendulumSnapshot
    
    var body: some View {
        Gymnazo.PendulumView(snapshot: snapshot)
    }
}

#Preview {
    PendulumView(runner: PendulumRunner())
}

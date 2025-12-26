//
//  MountainCarContinuousView.swift
//

import SwiftUI
import Gymnazo

struct MountainCarContinuousView: View {
    @Bindable var runner: MountainCarContinuousRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Mountain Car Continuous",
            environmentType: .mountainCarContinuous,
            algorithmType: "SAC",
            accentColor: .purple,
            canvasAspectRatio: 2.0,
            canvasMaxSize: CGSize(width: 600, height: 300),
            canvas: { snapshot in
                if let snapshot {
                    MountainCarContinuousCanvasView(snapshot: snapshot)
                }
            },
            configuration: {
                MountainCarContinuousConfigurationView(runner: runner)
            },
            charts: { columns in
                MountainCarContinuousChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.mountainCarContinuous(
                        maxStepsPerEpisode: runner.maxStepsPerEpisode,
                        goalVelocity: runner.goalVelocity
                    )
                )
            }
        )
    }
}

private struct MountainCarContinuousCanvasView: View {
    let snapshot: MountainCarSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.MountainCarView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}

#Preview {
    MountainCarContinuousView(runner: MountainCarContinuousRunner())
}

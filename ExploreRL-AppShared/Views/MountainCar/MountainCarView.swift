//
//  MountainCarView.swift
//

import SwiftUI
import Gymnazo

struct MountainCarView: View {
    @Bindable var runner: MountainCarRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Mountain Car",
            environmentType: .mountainCar,
            algorithmType: "DQN",
            accentColor: .green,
            canvasAspectRatio: 2.0,
            canvasMaxSize: CGSize(width: 600, height: 300),
            canvas: { snapshot in
                if let snapshot {
                    MountainCarCanvasView(snapshot: snapshot)
                }
            },
            configuration: {
                MountainCarConfigurationView(runner: runner)
            },
            charts: { columns in
                MountainCarChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.mountainCar(maxStepsPerEpisode: runner.maxStepsPerEpisode)
                )
            }
        )
    }
}

struct MountainCarCanvasView: View {
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
    MountainCarView(runner: MountainCarRunner())
}

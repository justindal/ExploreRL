//
//  LunarLanderView.swift
//

import SwiftUI
import Gymnazo

struct LunarLanderView: View {
    @Bindable var runner: LunarLanderRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Lunar Lander",
            environmentType: .lunarLander,
            algorithmType: "DQN",
            accentColor: .blue,
            canvasAspectRatio: 600.0 / 400.0,
            canvasMaxSize: CGSize(width: 700, height: 467),
            canvas: { snapshot in
                if let snapshot {
                    LunarLanderViewAdapter(snapshot: snapshot)
                }
            },
            configuration: {
                LunarLanderConfigurationView(runner: runner)
            },
            charts: { columns in
                LunarLanderChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.lunarLander(maxStepsPerEpisode: runner.maxStepsPerEpisode)
                )
            }
        )
    }
}

struct LunarLanderViewAdapter: View {
    let snapshot: LunarLanderSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.LunarLanderView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}

#Preview {
    LunarLanderView(runner: LunarLanderRunner())
}

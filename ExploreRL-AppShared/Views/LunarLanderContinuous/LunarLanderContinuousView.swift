//
//  LunarLanderContinuousView.swift
//

import SwiftUI
import Gymnazo

struct LunarLanderContinuousView: View {
    @Bindable var runner: LunarLanderContinuousRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Lunar Lander Continuous",
            environmentType: .lunarLanderContinuous,
            algorithmType: "SAC",
            accentColor: .teal,
            canvasAspectRatio: 600.0 / 400.0,
            canvasMaxSize: CGSize(width: 700, height: 467),
            canvas: { snapshot in
                if let snapshot {
                    LunarLanderContinuousViewAdapter(snapshot: snapshot)
                }
            },
            configuration: {
                LunarLanderContinuousConfigurationView(runner: runner)
            },
            charts: { columns in
                LunarLanderContinuousChartsView(runner: runner, columns: columns ?? [])
            }
        )
    }
}

struct LunarLanderContinuousViewAdapter: View {
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
    LunarLanderContinuousView(runner: LunarLanderContinuousRunner())
}

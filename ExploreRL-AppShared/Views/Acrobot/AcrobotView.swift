//
//  AcrobotView.swift
//

import SwiftUI
import Gymnazo

struct AcrobotView: View {
    @Bindable var runner: AcrobotRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Acrobot",
            environmentType: .acrobot,
            algorithmType: "DQN",
            accentColor: .red,
            canvasAspectRatio: 1.0,
            canvasMaxSize: CGSize(width: 500, height: 500),
            canvas: { snapshot in
                if let snapshot {
                    AcrobotViewAdapter(snapshot: snapshot)
                }
            },
            configuration: {
                AcrobotConfigurationView(runner: runner)
            },
            charts: { columns in
                AcrobotChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.acrobot(maxStepsPerEpisode: runner.maxStepsPerEpisode)
                )
            }
        )
    }
}

struct AcrobotViewAdapter: View {
    let snapshot: AcrobotSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.AcrobotView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}

#Preview {
    AcrobotView(runner: AcrobotRunner())
}

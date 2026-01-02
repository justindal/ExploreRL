import SwiftUI
import Gymnazo

struct CarRacingView: View {
    @Bindable var runner: CarRacingRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Car Racing",
            environmentType: .carRacing,
            algorithmType: "SAC",
            accentColor: .pink,
            canvasAspectRatio: 600.0 / 400.0,
            canvasMaxSize: CGSize(width: 700, height: 467),
            canvas: { snapshot in
                if let snapshot {
                    CarRacingViewAdapter(snapshot: snapshot)
                }
            },
            configuration: {
                CarRacingConfigurationView(runner: runner)
            },
            charts: { columns in
                CarRacingChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.carRacing(
                        maxStepsPerEpisode: runner.maxStepsPerEpisode,
                        lapCompletePercent: runner.lapCompletePercent,
                        domainRandomize: runner.domainRandomize,
                        useFrameStack: runner.useFrameStack,
                        frameStackSize: runner.frameStackSize
                    )
                )
            }
        )
    }
}

struct CarRacingViewAdapter: View {
    let snapshot: CarRacingSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.CarRacingView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}


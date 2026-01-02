import SwiftUI
import Gymnazo

struct CarRacingDiscreteView: View {
    @Bindable var runner: CarRacingDiscreteRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Car Racing Discrete",
            environmentType: .carRacingDiscrete,
            algorithmType: "DQN",
            accentColor: .gray,
            canvasAspectRatio: 600.0 / 400.0,
            canvasMaxSize: CGSize(width: 700, height: 467),
            canvas: { snapshot in
                if let snapshot {
                    CarRacingDiscreteViewAdapter(snapshot: snapshot)
                }
            },
            configuration: {
                CarRacingDiscreteConfigurationView(runner: runner)
            },
            charts: { columns in
                CarRacingDiscreteChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.carRacingDiscrete(
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

struct CarRacingDiscreteViewAdapter: View {
    let snapshot: CarRacingSnapshot
    
    var body: some View {
        #if canImport(SpriteKit)
        Gymnazo.CarRacingView(snapshot: snapshot)
        #else
        Text("SpriteKit not available")
        #endif
    }
}


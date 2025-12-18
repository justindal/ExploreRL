//
//  BlackjackView.swift
//

import SwiftUI
import Gymnazo

struct BlackjackView: View {
    @Bindable var runner: BlackjackRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Blackjack",
            environmentType: .blackjack,
            algorithmType: runner.selectedAlgorithm.rawValue,
            accentColor: .mint,
            canvasAspectRatio: 600.0 / 500.0,
            canvasMaxSize: CGSize(width: 600, height: 500),
            canvas: { snapshot in
                if let snapshot {
                    BlackjackCanvasView(snapshot: snapshot)
                }
            },
            configuration: {
                BlackjackConfigurationView(runner: runner)
            },
            charts: { columns in
                BlackjackChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.blackjack(
                        algorithmName: runner.selectedAlgorithm.rawValue,
                        natural: runner.natural,
                        sab: runner.sab,
                        maxStepsPerEpisode: runner.maxStepsPerEpisode
                    )
                )
            }
        )
    }
}

typealias BlackjackCanvasView = Gymnazo.BlackjackCanvasView

#Preview {
    BlackjackView(runner: BlackjackRunner())
}


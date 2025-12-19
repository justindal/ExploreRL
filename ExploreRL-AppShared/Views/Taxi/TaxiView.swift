//
//  TaxiView.swift
//

import SwiftUI
import Gymnazo

struct TaxiView: View {
    @Bindable var runner: TaxiRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Taxi",
            environmentType: .taxi,
            algorithmType: runner.selectedAlgorithm.rawValue,
            accentColor: .yellow,
            canvasAspectRatio: 340.0 / 360.0,
            canvasMaxSize: CGSize(width: 340, height: 360),
            canvas: { snapshot in
                if let snapshot {
                    TaxiCanvasView(snapshot: snapshot)
                }
            },
            configuration: {
                TaxiConfigurationView(runner: runner)
            },
            charts: { columns in
                TaxiChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.taxi(
                        algorithmName: runner.selectedAlgorithm.rawValue,
                        isRainy: runner.isRainy,
                        ficklePassenger: runner.ficklePassenger,
                        maxStepsPerEpisode: runner.maxStepsPerEpisode
                    )
                )
            }
        )
    }
}

typealias TaxiCanvasView = Gymnazo.TaxiCanvasView

#Preview {
    TaxiView(runner: TaxiRunner())
}


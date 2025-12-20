//
//  CliffWalkingView.swift
//

import SwiftUI
import Gymnazo

struct CliffWalkingView: View {
    @Bindable var runner: CliffWalkingRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Cliff Walking",
            environmentType: .cliffWalking,
            algorithmType: runner.selectedAlgorithm.rawValue,
            accentColor: .brown,
            canvasAspectRatio: 640.0 / 240.0,
            canvasMaxSize: CGSize(width: 640, height: 240),
            canvas: { snapshot in
                if let snapshot {
                    CliffWalkingCanvasView(snapshot: snapshot)
                }
            },
            configuration: {
                CliffWalkingConfigurationView(runner: runner)
            },
            charts: { columns in
                CliffWalkingChartsView(runner: runner, columns: columns ?? [])
            },
            info: {
                EnvironmentInfoTabView(
                    model: EnvironmentInfoTabModels.cliffWalking(
                        algorithmName: runner.selectedAlgorithm.rawValue,
                        isSlippery: runner.isSlippery,
                        maxStepsPerEpisode: runner.maxStepsPerEpisode
                    )
                )
            }
        )
    }
}

typealias CliffWalkingCanvasView = Gymnazo.CliffWalkingCanvasView

#Preview {
    CliffWalkingView(runner: CliffWalkingRunner())
}


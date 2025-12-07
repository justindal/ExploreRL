//
//  FrozenLakeView.swift
//

import SwiftUI
import Gymnazo

struct FrozenLakeView: View {
    @Bindable var runner: FrozenLakeRunner
    
    var body: some View {
        EnvironmentView(
            runner: runner,
            environmentName: "Frozen Lake",
            environmentType: .frozenLake,
            algorithmType: runner.selectedAlgorithm.rawValue,
            accentColor: .cyan,
            canvasAspectRatio: 1.0,
            canvasMaxSize: CGSize(width: 500, height: 500),
            canvas: { snapshot in
                if let snapshot {
                    FrozenLakeCanvasView(snapshot: snapshot)
                        .overlay {
                            if runner.showPolicy, let policy = runner.currentPolicy {
                                PolicyOverlayView(map: runner.currentMap, policy: policy)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            },
            configuration: {
                FrozenLakeConfigurationView(runner: runner)
            },
            charts: { columns in
                FrozenLakeChartsView(runner: runner, columns: columns ?? [])
            }
        )
    }
}

typealias FrozenLakeCanvasView = Gymnazo.FrozenLakeCanvasView

#Preview {
    FrozenLakeView(runner: FrozenLakeRunner())
}


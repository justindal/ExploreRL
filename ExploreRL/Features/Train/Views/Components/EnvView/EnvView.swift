//
//  EnvView.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-04.
//

import Gymnazo
import SwiftUI

struct EnvView: View {
    let env: any Env
    let snapshot: (any Sendable)?
    var renderVersion: Int = 0
    @State private var output: RenderOutput?

    var body: some View {
        Group {
            if let snapshot {
                snapshotView(snapshot)
            } else if let output {
                switch output {
                case .ansi(let text):
                    ansiView(text)

                case .other(let snapshot):
                    snapshotView(snapshot)

                #if canImport(CoreGraphics)
                    case .rgbArray(let image):
                        cgImageView(image)

                    case .statePixels(let image):
                        cgImageView(image)
                #endif
                }
            } else {
                unavailableView(title: "No Preview Available")
            }
        }
        .onChange(of: renderVersion, initial: true) { _, _ in
            updateOutput()
        }
    }

    @ViewBuilder
    private func ansiView(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    #if canImport(CoreGraphics)
        @ViewBuilder
        private func cgImageView(_ image: CGImage) -> some View {
            Image(image, scale: 1, label: Text("Environment frame"))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    #endif

    @ViewBuilder
    private func snapshotView(_ snapshot: any Sendable) -> some View {
        switch snapshot {
        case let s as FrozenLakeRenderSnapshot:
            FixedSizeEnvWrapper(
                baseSize: CGSize(
                    width: CGFloat(s.cols) * 100,
                    height: CGFloat(s.rows) * 100
                )
            ) {
                FrozenLakeCanvasView(snapshot: s)
            }

        case let s as BlackjackRenderSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 600, height: 500)) {
                BlackjackCanvasView(snapshot: s)
            }

        case let s as CliffWalkingRenderSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 640, height: 240)) {
                CliffWalkingCanvasView(snapshot: s)
            }

        case let s as TaxiRenderSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 340, height: 360)) {
                TaxiCanvasView(snapshot: s)
            }

        case let s as CartPoleSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 600, height: 400)) {
                CartPoleView(snapshot: s)
            }

        case let s as PendulumSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 400, height: 400)) {
                PendulumView(snapshot: s)
            }

        case let s as AcrobotSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 500, height: 500)) {
                AcrobotView(snapshot: s)
            }

        case let s as MountainCarSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 600, height: 400)) {
                MountainCarView(snapshot: s)
            }

        case let s as LunarLanderSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 600, height: 400)) {
                LunarLanderView(snapshot: s)
            }

        case let s as CarRacingSnapshot:
            FixedSizeEnvWrapper(baseSize: CGSize(width: 600, height: 400)) {
                CarRacingView(snapshot: s)
            }

        default:
            ContentUnavailableView(
                "Renderer Not Implemented",
                systemImage: "questionmark.square.dashed"
            )
        }
    }

    @ViewBuilder
    private func unavailableView(title: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: "eye.slash",
            description: Text("This environment doesn't support preview rendering yet.")
        )
    }

    private func updateOutput() {
        guard snapshot == nil else { return }
        do {
            output = try env.render()
        } catch {
            output = nil
        }
    }
}

private struct FixedSizeEnvWrapper<Content: View>: View {
    let baseSize: CGSize
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            let scaleX = proxy.size.width / baseSize.width
            let scaleY = proxy.size.height / baseSize.height
            let scale = min(scaleX, scaleY, 1.0)

            content
                .frame(width: baseSize.width, height: baseSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 12 / scale))
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(baseSize.width / baseSize.height, contentMode: .fit)
        .frame(maxWidth: baseSize.width, maxHeight: min(baseSize.height, 480))
    }
}

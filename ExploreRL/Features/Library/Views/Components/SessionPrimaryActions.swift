import SwiftUI

struct SessionPrimaryActions: View {
    let onLoad: () -> Void
    let onEvaluate: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var accessibleLabelHeight = 44

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    loadButton
                    evaluateButton
                }
            } else {
                Grid(horizontalSpacing: 12) {
                    GridRow {
                        loadButton
                        evaluateButton
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .controlSize(.large)
        .multilineTextAlignment(.center)
        .modify { content in
            if #available(iOS 26.0, macOS 26.0, *) {
                GlassEffectContainer(spacing: 14) { content }
            } else {
                content
            }
        }
    }

    private var loadButton: some View {
        Button {
            onLoad()
        } label: {
            Label("Load in Training", systemImage: "play.fill")
                .frame(
                    maxWidth: .infinity,
                    minHeight: dynamicTypeSize.isAccessibilitySize ? accessibleLabelHeight : nil,
                    maxHeight: .infinity
                )
        }
        .modify { button in
            if #available(iOS 26.0, macOS 26.0, *) {
                button
                    .buttonStyle(.glass(.regular.tint(.blue).interactive()))
                    #if os(macOS)
                        .tint(.blue)
                    #endif
            } else {
                button.buttonStyle(.borderedProminent)
            }
        }
    }

    private var evaluateButton: some View {
        Button {
            onEvaluate()
        } label: {
            Label("Evaluate", systemImage: "checkmark.circle")
                .frame(
                    maxWidth: .infinity,
                    minHeight: dynamicTypeSize.isAccessibilitySize ? accessibleLabelHeight : nil,
                    maxHeight: .infinity
                )
        }
        .modify { button in
            if #available(iOS 26.0, macOS 26.0, *) {
                button
                    .buttonStyle(.glass(.regular.tint(.green).interactive()))
                    #if os(macOS)
                        .tint(.green)
                    #endif
            } else {
                button
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
    }
}

#Preview("Narrow actions", traits: .sizeThatFitsLayout) {
    SessionPrimaryActions(onLoad: {}, onEvaluate: {})
        .padding()
        .frame(width: 370)
}

#Preview("Large text", traits: .sizeThatFitsLayout) {
    SessionPrimaryActions(onLoad: {}, onEvaluate: {})
        .padding()
        .frame(width: 370)
        .dynamicTypeSize(.accessibility2)
}

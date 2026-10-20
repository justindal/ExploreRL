import SwiftUI

struct HomeSessionRow: View {
    let session: SavedSession
    let onLoad: () -> Void
    let onEvaluate: () -> Void
    let onOpenLibrary: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: AppLayout.spacing) {
                    sessionButton
                        .frame(minWidth: 240)
                    actions
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                sessionButton
                actions
            }
        }
    }

    private var sessionButton: some View {
        Button(action: onLoad) {
            SavedSessionRow(session: session)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Loads this agent in the training workspace")
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            if !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: AppLayout.compactSpacing) {
                    actionButtons
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: AppLayout.compactSpacing) {
                actionButtons
            }
        }
        .modify { content in
            if #available(iOS 26.0, macOS 26.0, *) {
                GlassEffectContainer(spacing: 10) {
                    content
                }
            } else {
                content
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HomeSessionActionButton(
            title: "Evaluate",
            systemImage: "play.circle",
            tint: .green,
            isProminent: true,
            action: onEvaluate
        )
        HomeSessionActionButton(
            title: "View in Library",
            systemImage: "books.vertical",
            tint: .primary,
            isProminent: false,
            action: onOpenLibrary
        )
    }
}

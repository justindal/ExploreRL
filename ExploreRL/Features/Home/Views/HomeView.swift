import Gymnazo
import SwiftUI

struct HomeView: View {
    let envSpecs: [EnvSpec]
    let showExplore: Bool
    let onTrainEnvironment: (String) -> Void
    let onOpenLibrary: () -> Void
    let onOpenEvaluate: () -> Void
    let onOpenExplore: () -> Void
    let onOpenSettings: () -> Void
    let onLoadSession: (SavedSession) -> Void
    let onEvaluateSession: (SavedSession) -> Void

    @State private var libraryViewModel = LibraryViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var recentSessions: [SavedSession] {
        Array(libraryViewModel.sortedAndFilteredSessions(matching: "").prefix(4))
    }

    private var featuredEnvironments: [EnvSpec] {
        EnvCategory.allCases.reduce(into: [EnvSpec]()) { result, category in
            result.append(contentsOf: envSpecs.filter { $0.category == category }.prefix(1))
        }
        .prefix(8)
        .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                header
                recentSessionsSection
                environments
                quickActions
            }
            .frame(maxWidth: AppLayout.contentMaxWidth, alignment: .leading)
            .padding(AppLayout.sectionSpacing)
            .frame(maxWidth: .infinity)
        }
        .background(.background)
        .navigationTitle("Home")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            libraryViewModel.loadSessions()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ExploreRL")
                .font(.largeTitle.weight(.bold))
            Text("Train, evaluate, and understand reinforcement-learning agents.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.title2.weight(.semibold))

            LazyVGrid(
                columns: gridColumns(minimum: 220),
                spacing: AppLayout.spacing
            ) {
                HomeActionCard(
                    title: "Evaluate",
                    message: "Run and compare saved agents.",
                    systemImage: "play.circle",
                    action: onOpenEvaluate
                )
                HomeActionCard(
                    title: "Library",
                    message: "Saved agents and training history.",
                    systemImage: "books.vertical",
                    action: onOpenLibrary
                )
                if showExplore {
                    HomeActionCard(
                        title: "Explore",
                        message: "Learn reinforcement-learning concepts.",
                        systemImage: "graduationcap",
                        action: onOpenExplore
                    )
                }
                HomeActionCard(
                    title: "Settings",
                    message: "Preferences and diagnostics.",
                    systemImage: "gearshape",
                    action: onOpenSettings
                )
            }
        }
    }

    private var environments: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Start training")
                    .font(.title2.weight(.semibold))
                Text("Pick an environment to open its training workspace.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if featuredEnvironments.isEmpty {
                ContentUnavailableView(
                    "Loading environments",
                    systemImage: "square.grid.2x2",
                    description: Text("Gymnazo environments will appear here shortly.")
                )
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(
                    .thinMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius))
            } else {
                LazyVGrid(
                    columns: gridColumns(minimum: 260),
                    spacing: AppLayout.spacing
                ) {
                    ForEach(featuredEnvironments, id: \.id) { spec in
                        HomeEnvironmentCard(spec: spec) {
                            onTrainEnvironment(spec.id)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentSessionsSection: some View {
        if !recentSessions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppLayout.compactSpacing))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
                layout {
                    sectionHeading("Recent agents", systemImage: "clock")
                    if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                    Button("View all") {
                        onOpenLibrary()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .frame(minHeight: 44)
                }

                VStack(spacing: 0) {
                    ForEach(recentSessions) { session in
                        HomeSessionRow(
                            session: session,
                            onLoad: { onLoadSession(session) },
                            onEvaluate: { onEvaluateSession(session) },
                            onOpenLibrary: onOpenLibrary
                        )
                        .padding(.horizontal, AppLayout.panelPadding)
                        .padding(.vertical, 10)

                        if session.id != recentSessions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(
                    .thinMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius))
            }
        }
    }

    private func sectionHeading(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title2.weight(.semibold))
    }

    private func gridColumns(minimum: CGFloat) -> [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: minimum), spacing: AppLayout.spacing)]
    }
}

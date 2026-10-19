#if os(macOS)
    import AppKit
    import Gymnazo
    import SwiftUI

    struct MacHomeView: View {
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
        private var recentSessions: [SavedSession] {
            Array(libraryViewModel.sortedAndFilteredSessions(matching: "").prefix(4))
        }

        private var featuredEnvironments: [EnvSpec] {
            EnvCategory.allCases.reduce(into: [EnvSpec]()) { result, category in
                result.append(contentsOf: envSpecs.filter { $0.category == category }.prefix(2))
            }
            .prefix(8)
            .map { $0 }
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    header
                    quickActions
                    environments
                    recentSessionsSection
                }
                .frame(maxWidth: AppLayout.contentMaxWidth, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("Home")
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
                    columns: [GridItem(.adaptive(minimum: 220), spacing: AppLayout.spacing)],
                    spacing: AppLayout.spacing
                ) {
                    MacHomeActionCard(
                        title: "Evaluate",
                        message: "Run and compare saved agents.",
                        systemImage: "play.circle",
                        action: onOpenEvaluate
                    )
                    MacHomeActionCard(
                        title: "Library",
                        message: "Saved agents and training history.",
                        systemImage: "books.vertical",
                        action: onOpenLibrary
                    )
                    if showExplore {
                        MacHomeActionCard(
                            title: "Explore",
                            message: "Learn reinforcement-learning concepts.",
                            systemImage: "graduationcap",
                            action: onOpenExplore
                        )
                    }
                    MacHomeActionCard(
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
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start training")
                            .font(.title2.weight(.semibold))
                        Text("Pick an environment to open its training workspace.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("More in the sidebar")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
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
                        columns: [GridItem(.adaptive(minimum: 260), spacing: AppLayout.spacing)],
                        spacing: AppLayout.spacing
                    ) {
                        ForEach(featuredEnvironments, id: \.id) { spec in
                            MacHomeEnvironmentCard(spec: spec) {
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
                    HStack(alignment: .firstTextBaseline) {
                        sectionHeading("Recent agents", systemImage: "clock")
                        Spacer()
                        Button("View all") {
                            onOpenLibrary()
                        }
                        .buttonStyle(.link)
                    }

                    VStack(spacing: 0) {
                        ForEach(recentSessions) { session in
                            HStack(spacing: 12) {
                                Button {
                                    onLoadSession(session)
                                } label: {
                                    SavedSessionRow(session: session)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                HStack(spacing: 8) {
                                    MacHomeSessionActionButton(
                                        title: "Evaluate",
                                        systemImage: "play.circle",
                                        tint: .green,
                                        isProminent: true
                                    ) {
                                        onEvaluateSession(session)
                                    }

                                    MacHomeSessionActionButton(
                                        title: "View in Library",
                                        systemImage: "books.vertical",
                                        tint: .primary,
                                        isProminent: false,
                                        action: onOpenLibrary
                                    )
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

    }

#endif

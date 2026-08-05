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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
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
                    columns: [
                        GridItem(.flexible(minimum: 220), spacing: AppLayout.spacing),
                        GridItem(.flexible(minimum: 220), spacing: AppLayout.spacing),
                        GridItem(.flexible(minimum: 220), spacing: AppLayout.spacing),
                        GridItem(.flexible(minimum: 220), spacing: AppLayout.spacing),
                    ],
                    spacing: AppLayout.spacing
                ) {
                    MacHomeActionCard(
                        title: "Evaluate",
                        message: "Run a saved agent and compare its results.",
                        systemImage: "play.circle",
                        tint: .green,
                        action: onOpenEvaluate
                    )
                    MacHomeActionCard(
                        title: "View in Library",
                        message: "Open saved agents, models, and training history.",
                        systemImage: "books.vertical",
                        tint: .orange,
                        action: onOpenLibrary
                    )
                    if showExplore {
                        MacHomeActionCard(
                            title: "Explore",
                            message: "Learn the ideas behind each experiment.",
                            systemImage: "graduationcap",
                            tint: .purple,
                            action: onOpenExplore
                        )
                    }
                    MacHomeActionCard(
                        title: "Settings",
                        message: "Manage preferences and app diagnostics.",
                        systemImage: "gearshape",
                        tint: .gray,
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
                        columns: [
                            GridItem(.flexible(minimum: 260), spacing: AppLayout.spacing),
                            GridItem(.flexible(minimum: 260), spacing: AppLayout.spacing),
                        ],
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

    private struct MacHomeActionCard: View {
        let title: String
        let message: String
        let systemImage: String
        let tint: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(tint)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                .padding(AppLayout.panelPadding)
                .background(
                    .thinMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AppLayout.panelRadius)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens this area in ExploreRL")
        }
    }

    private struct MacHomeEnvironmentCard: View {
        let spec: EnvSpec
        let action: () -> Void

        private var title: String {
            spec.displayName ?? spec.name
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(spec.category?.rawValue ?? "Environment")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }

                    Text(spec.description ?? "Configure this environment and train an agent.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
                .padding(AppLayout.panelPadding)
                .background(
                    .regularMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AppLayout.panelRadius)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Train \(title)")
            .accessibilityHint("Opens training for this environment")
        }
    }

    private struct MacHomeSessionActionButton: View {
        let title: String
        let systemImage: String
        let tint: Color
        let isProminent: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Label(title, systemImage: systemImage)
            }
            .modify { button in
                if #available(iOS 26.0, macOS 26.0, *) {
                    if isProminent {
                        button
                            .buttonStyle(.glass(.regular.tint(tint).interactive()))
                            .controlSize(.small)
                            #if os(macOS)
                                .tint(tint)
                            #endif
                    } else {
                        button
                            .buttonStyle(.glass(.clear))
                            .controlSize(.small)
                    }
                } else if isProminent {
                    button
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(tint)
                } else {
                    button
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.primary)
                }
            }
        }
    }
#endif

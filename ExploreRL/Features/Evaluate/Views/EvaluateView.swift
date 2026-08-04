//
//  EvaluateView.swift
//  ExploreRL
//

import SwiftUI

struct EvaluateView: View {
    @Binding var sessionToLoad: SavedSession?
    var onGoToLibrary: (() -> Void)?
    @State private var viewModel = EvaluateViewModel()
    @State private var selectedSession: SavedSession?
    @State private var searchText = ""
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    init(sessionToLoad: Binding<SavedSession?> = .constant(nil), onGoToLibrary: (() -> Void)? = nil)
    {
        _sessionToLoad = sessionToLoad
        self.onGoToLibrary = onGoToLibrary
    }

    var body: some View {
        Group {
            #if os(macOS)
                macLayout
            #else
                mobileLayout
            #endif
        }
        .onAppear {
            viewModel.loadSessions()
        }
        .onChange(of: sessionToLoad) { _, newValue in
            guard let session = newValue else { return }
            sessionToLoad = nil
            viewModel.loadSessions()
            selectedSession = session
        }
    }

    #if os(macOS)
        private var macLayout: some View {
            HSplitView {
                VStack(spacing: 0) {
                    TextField("Search agents", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(AppLayout.compactSpacing)

                    Divider()

                    browserContent
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                }
                .frame(
                    minWidth: 280,
                    idealWidth: 340,
                    maxWidth: 420,
                    maxHeight: .infinity,
                    alignment: .top
                )

                NavigationStack {
                    if let selectedSession {
                        EvaluateDetailView(
                            session: selectedSession,
                            vm: viewModel,
                            showsCloseButton: false
                        )
                    } else {
                        ContentUnavailableView(
                            "Select an Agent",
                            systemImage: "play.square.stack",
                            description: Text(
                                "Choose a saved agent to configure and run an evaluation."
                            )
                        )
                    }
                }
                .frame(
                    minWidth: 540,
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Evaluate")
        }
    #else
        private var mobileLayout: some View {
            Group {
                if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                    NavigationSplitView {
                        browserContent
                            .navigationTitle("Evaluate")
                            .searchable(text: $searchText, prompt: "Search agents")
                            .navigationSplitViewColumnWidth(
                                min: 280,
                                ideal: 340,
                                max: 420
                            )
                    } detail: {
                        if let selectedSession {
                            EvaluateDetailView(
                                session: selectedSession,
                                vm: viewModel,
                                showsCloseButton: false
                            )
                        } else {
                            ContentUnavailableView(
                                "Select an Agent",
                                systemImage: "play.square.stack",
                                description: Text(
                                    "Choose a saved agent to configure and run an evaluation."
                                )
                            )
                        }
                    }
                } else {
                    NavigationStack {
                        browserContent
                            .navigationTitle("Evaluate")
                            .searchable(text: $searchText, prompt: "Search agents")
                    }
                    .sheet(item: $selectedSession) { session in
                        NavigationStack {
                            EvaluateDetailView(session: session, vm: viewModel)
                        }
                    }
                }
            }
        }
    #endif

    @ViewBuilder
    private var browserContent: some View {
        if viewModel.sessions.isEmpty {
            ContentUnavailableView {
                Label("No Agents to Evaluate", systemImage: "play.square.stack")
            } description: {
                Text("Agents appear here after you train and save them in the Library.")
            } actions: {
                if let onGoToLibrary {
                    Button("Go to Library") {
                        onGoToLibrary()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else if filteredSessions.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            sessionList
        }
    }

    @ViewBuilder
    private var sessionList: some View {
        List {
            ForEach(groupedSessions, id: \.algorithm) { group in
                Section(group.algorithm) {
                    ForEach(group.sessions) { session in
                        EvaluateSessionRow(session: session) {
                            selectedSession = session
                        }
                    }
                }
            }
        }
        .listStyle(evaluateListStyle)
    }

    private var groupedSessions: [(algorithm: String, sessions: [SavedSession])] {
        let grouped = Dictionary(grouping: filteredSessions, by: \.algorithmType.rawValue)
        return grouped.keys.sorted().map { key in
            (algorithm: key, sessions: grouped[key] ?? [])
        }
    }

    private var filteredSessions: [SavedSession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.sessions }

        return viewModel.sessions.filter { session in
            session.name.localizedStandardContains(query)
                || session.environmentID.localizedStandardContains(query)
                || session.algorithmType.rawValue.localizedStandardContains(query)
        }
    }

    private var evaluateListStyle: some ListStyle {
        #if os(macOS)
            return InsetListStyle()
        #else
            return InsetGroupedListStyle()
        #endif
    }
}

//
//  EvaluateView.swift
//  ExploreRL
//

import SwiftUI

struct EvaluateView: View {
    @Binding var sessionToLoad: SavedSession?
    var onGoToLibrary: (() -> Void)?
    var usesWorkspaceNavigation: Bool
    @State private var viewModel = EvaluateViewModel()
    @State private var selectedSession: SavedSession?
    @State private var searchText = ""

    init(
        sessionToLoad: Binding<SavedSession?> = .constant(nil),
        onGoToLibrary: (() -> Void)? = nil,
        usesWorkspaceNavigation: Bool = false
    )
    {
        _sessionToLoad = sessionToLoad
        self.onGoToLibrary = onGoToLibrary
        self.usesWorkspaceNavigation = usesWorkspaceNavigation
        _selectedSession = State(
            initialValue: usesWorkspaceNavigation ? sessionToLoad.wrappedValue : nil
        )
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
        .onChange(of: sessionToLoad, initial: true) { _, newValue in
            guard let session = newValue else { return }
            sessionToLoad = nil
            viewModel.loadSessions()
            selectSession(session)
        }
        .onDisappear {
            if usesWorkspaceNavigation {
                viewModel.stopEvaluation()
            }
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
                if usesWorkspaceNavigation {
                    NavigationStack {
                        if let selectedSession {
                            EvaluateDetailView(
                                session: selectedSession, vm: viewModel, showsCloseButton: false
                            )
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("Agents", systemImage: "chevron.backward") {
                                        viewModel.stopEvaluation()
                                        self.selectedSession = nil
                                    }
                                }
                            }
                        } else {
                            browserContent
                                .navigationTitle("Evaluate")
                                .searchable(text: $searchText, prompt: "Search agents")
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
                            selectSession(session)
                        }
                    }
                }
            }
        }
        .listStyle(evaluateListStyle)
    }

    private func selectSession(_ session: SavedSession) {
        selectedSession = session
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

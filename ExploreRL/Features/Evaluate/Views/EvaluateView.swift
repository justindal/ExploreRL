//
//  EvaluateView.swift
//  ExploreRL
//

import SwiftUI

struct EvaluateView: View {
    @Binding var sessionToLoad: SavedSession?
    var onGoToLibrary: (() -> Void)?
    @State private var viewModel = EvaluateViewModel()
    @State private var selectedSessionID: UUID?

    init(sessionToLoad: Binding<SavedSession?> = .constant(nil), onGoToLibrary: (() -> Void)? = nil) {
        _sessionToLoad = sessionToLoad
        self.onGoToLibrary = onGoToLibrary
    }

    var body: some View {
        NavigationSplitView {
            Group {
                if viewModel.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Saved Sessions",
                        systemImage: "tray",
                        description: Text("Train an agent and save it to evaluate here.")
                    )
                } else {
                    sessionList
                }
            }
            .navigationTitle("Evaluate")
            .onAppear {
                viewModel.loadSessions()
            }
            .onChange(of: sessionToLoad) { _, newValue in
                guard let session = newValue else { return }
                selectedSessionID = session.id
                sessionToLoad = nil
            }
        } detail: {
            Group {
                if let session = selectedSession {
                    EvaluateDetailView(session: session, vm: viewModel)
                } else if viewModel.sessions.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Sessions", systemImage: "tray")
                    } description: {
                        Text("Train an agent and save it to evaluate here.")
                    } actions: {
                        if let onGoToLibrary {
                            Button("Go to Library") {
                                onGoToLibrary()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Select a Session",
                        systemImage: "play.circle"
                    )
                }
            }
        }
    }

    private var selectedSession: SavedSession? {
        guard let id = selectedSessionID else { return nil }
        return viewModel.sessions.first { $0.id == id }
    }

    @ViewBuilder
    private var sessionList: some View {
        List(selection: $selectedSessionID) {
            ForEach(groupedSessions, id: \.envID) { group in
                Section(group.envID) {
                    ForEach(group.sessions) { session in
                        SavedSessionRow(session: session)
                            .tag(session.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var groupedSessions: [(envID: String, sessions: [SavedSession])] {
        let grouped = Dictionary(grouping: viewModel.sessions, by: \.environmentID)
        return grouped.keys.sorted().map { key in
            (envID: key, sessions: grouped[key] ?? [])
        }
    }
}

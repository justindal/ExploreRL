//
//  EvaluateView.swift
//  ExploreRL
//

import SwiftUI

struct EvaluateView: View {
    @Binding var sessionToLoad: SavedSession?
    var onGoToLibrary: (() -> Void)?
    @State private var viewModel = EvaluateViewModel()
    @State private var path: [UUID] = []

    init(sessionToLoad: Binding<SavedSession?> = .constant(nil), onGoToLibrary: (() -> Void)? = nil) {
        _sessionToLoad = sessionToLoad
        self.onGoToLibrary = onGoToLibrary
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.sessions.isEmpty {
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
                    sessionList
                }
            }
            .navigationTitle("Evaluate")
            .onAppear {
                viewModel.loadSessions()
            }
            .onChange(of: sessionToLoad) { _, newValue in
                guard let session = newValue else { return }
                sessionToLoad = nil
                viewModel.loadSessions()
                path = [session.id]
            }
            .navigationDestination(for: UUID.self) { sessionID in
                if let session = viewModel.sessions.first(where: { $0.id == sessionID }) {
                    EvaluateDetailView(session: session, vm: viewModel)
                } else {
                    ContentUnavailableView(
                        "Session Not Found",
                        systemImage: "exclamationmark.triangle"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var sessionList: some View {
        List {
            ForEach(groupedSessions, id: \.envID) { group in
                Section(group.envID) {
                    ForEach(group.sessions) { session in
                        NavigationLink(value: session.id) {
                            SavedSessionRow(session: session)
                        }
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

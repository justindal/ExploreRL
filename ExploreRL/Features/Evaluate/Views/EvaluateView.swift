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

    init(sessionToLoad: Binding<SavedSession?> = .constant(nil), onGoToLibrary: (() -> Void)? = nil)
    {
        _sessionToLoad = sessionToLoad
        self.onGoToLibrary = onGoToLibrary
    }

    var body: some View {
        NavigationStack {
            Group {
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
                selectedSession = session
            }
            .sheet(item: $selectedSession) { session in
                EvaluateDetailView(session: session, vm: viewModel)
            }
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
        let grouped = Dictionary(grouping: viewModel.sessions, by: \.algorithmType.rawValue)
        return grouped.keys.sorted().map { key in
            (algorithm: key, sessions: grouped[key] ?? [])
        }
    }

    private var evaluateListStyle: some ListStyle {
        #if os(macOS)
            return SidebarListStyle()
        #else
            return InsetGroupedListStyle()
        #endif
    }
}

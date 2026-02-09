//
//  LoadSessionSheet.swift
//  ExploreRL
//

import SwiftUI

struct LoadSessionSheet: View {
    let environmentID: String
    let onLoad: (SavedSession) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [SavedSession]
    @State private var showAll = false

    init(environmentID: String, onLoad: @escaping (SavedSession) -> Void) {
        self.environmentID = environmentID
        self.onLoad = onLoad
        _sessions = State(initialValue: SessionStorage.shared.listSessions())
    }

    private var filteredSessions: [SavedSession] {
        if showAll {
            return sessions
        }
        return sessions.filter { $0.environmentID == environmentID }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Saved Sessions",
                        systemImage: "tray",
                        description: Text("Save a training session first.")
                    )
                } else if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions for \(environmentID)",
                        systemImage: "tray",
                        description: Text(
                            "Toggle \"Show All\" to see sessions from other environments.")
                    )
                } else {
                    List(filteredSessions) { session in
                        Button {
                            onLoad(session)
                            dismiss()
                        } label: {
                            SavedSessionRow(session: session)
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle("Load Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !sessions.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Toggle("Show All", isOn: $showAll)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .padding()
                    }
                }
            }
        }
    }
}

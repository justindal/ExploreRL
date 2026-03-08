import SwiftUI

struct LoadSessionSheet: View {
    let environmentID: String
    let onLoad: (SavedSession) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LibraryViewModel()

    private var filteredSessions: [SavedSession] {
        viewModel.sessions.filter { $0.environmentID == environmentID }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty {
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
                            "Save a training session for this environment first."
                        )
                    )
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            Button {
                                onLoad(session)
                                dismiss()
                            } label: {
                                SavedSessionRow(session: session)
                            }
                            .tint(.primary)
                            #if os(macOS)
                            .listRowSeparator(.hidden)
                            #endif
                        }
                    }
                }
            }
            .navigationTitle("Load Session")
            #if os(macOS)
            .frame(minWidth: 400, idealWidth: 500, minHeight: 400)
            #endif
            .onAppear {
                viewModel.loadSessions()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

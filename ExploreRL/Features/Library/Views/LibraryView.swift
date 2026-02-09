import SwiftUI

struct LibraryView: View {
    var onLoad: (SavedSession) -> Void
    var onEvaluate: (SavedSession) -> Void

    @State private var viewModel = LibraryViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var selectedSessionID: UUID?
    @State private var showImportPicker = false

    private var hasDeleteError: Binding<Bool> {
        Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )
    }

    private var hasTransferError: Binding<Bool> {
        Binding(
            get: { viewModel.transferError != nil },
            set: { if !$0 { viewModel.transferError = nil } }
        )
    }

    private var hasImportResult: Binding<Bool> {
        Binding(
            get: { viewModel.lastImportedCount != nil },
            set: { if !$0 { viewModel.lastImportedCount = nil } }
        )
    }

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            sidebarContent
        } detail: {
            detailContent
        }
        .toolbar(removing: .sidebarToggle)
        .onAppear {
            viewModel.loadSessions()
        }
        .onChange(of: viewModel.sessions) { _, _ in
            if let selectedSessionID, !viewModel.sessions.contains(where: { $0.id == selectedSessionID }) {
                self.selectedSessionID = nil
            }
        }
        .alert("Delete Failed", isPresented: hasDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.deleteError ?? "")
        }
        .alert("Transfer Failed", isPresented: hasTransferError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.transferError ?? "")
        }
        .alert("Import Complete", isPresented: hasImportResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Imported \(viewModel.lastImportedCount ?? 0) session(s).")
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [SessionStorage.archiveContentType],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.importSessions(from: urls)
            case .failure(let error):
                viewModel.transferError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        Group {
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "No Saved Sessions",
                    systemImage: "tray",
                    description: Text("Train an agent and save your progress to see it here.")
                )
            } else {
                List(selection: $selectedSessionID) {
                    ForEach(viewModel.sessions) { session in
                        NavigationLink(value: session.id) {
                            SavedSessionRow(
                                session: session,
                                size: viewModel.sessionSizes[session.id]
                            )
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteSessions(at: offsets)
                    }
                }
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImportPicker = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .navigationDestination(for: UUID.self) { sessionID in
            if let session = viewModel.sessions.first(where: { $0.id == sessionID }) {
                LibraryDetailView(
                    session: session,
                    onLoad: onLoad,
                    onEvaluate: onEvaluate,
                    onDelete: { viewModel.delete(session: session) }
                )
            } else {
                ContentUnavailableView(
                    "Session Not Found",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let selectedSessionID,
           let session = viewModel.sessions.first(where: { $0.id == selectedSessionID }) {
            LibraryDetailView(
                session: session,
                onLoad: onLoad,
                onEvaluate: onEvaluate,
                onDelete: { viewModel.delete(session: session) }
            )
        } else if viewModel.sessions.isEmpty {
            ContentUnavailableView(
                "No Saved Sessions",
                systemImage: "tray",
                description: Text("Train an agent and save your progress to see it here.")
            )
        } else {
            ContentUnavailableView(
                "Select a Session",
                systemImage: "sidebar.left"
            )
        }
    }
}

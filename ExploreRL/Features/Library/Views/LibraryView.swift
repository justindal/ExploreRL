import SwiftUI

struct LibraryView: View {
    var onLoad: (SavedSession) -> Void
    var onEvaluate: (SavedSession) -> Void

    @State private var viewModel = LibraryViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var selectedSessionID: UUID?
    @State private var showImportPicker = false
    @State private var searchText = ""
    @State private var shareURL: URL?

    private var filteredSessions: [SavedSession] {
        viewModel.filteredSessions(matching: searchText)
    }

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

    private var hasExportError: Binding<Bool> {
        Binding(
            get: { viewModel.exportError != nil },
            set: { if !$0 { viewModel.exportError = nil } }
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
        .alert("Export Failed", isPresented: hasExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.exportError ?? "")
        }
        .modify { content in
            #if os(iOS)
            content.sheet(isPresented: Binding(
                get: { shareURL != nil },
                set: { if !$0 { shareURL = nil } }
            )) {
                if let shareURL {
                    SessionShareSheet(url: shareURL)
                        .presentationDetents([.medium])
                }
            }
            #else
            content
            #endif
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
        .searchable(
            text: $searchText,
            placement: .sidebar,
            prompt: "Search sessions"
        )
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
            } else if filteredSessions.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(selection: $selectedSessionID) {
                    ForEach(filteredSessions) { session in
                        NavigationLink(value: session.id) {
                            SavedSessionRow(
                                session: session,
                                size: viewModel.sessionSizes[session.id]
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.delete(session: session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                onLoad(session)
                            } label: {
                                Label("Load Session", systemImage: "play.fill")
                            }
                            Button {
                                onEvaluate(session)
                            } label: {
                                Label("Evaluate", systemImage: "checkmark.circle")
                            }
                            Button {
                                exportAndShare(session)
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            Divider()
                            Button(role: .destructive) {
                                viewModel.delete(session: session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { offsets in
                        deleteFilteredSessions(at: offsets)
                    }
                }
                .listStyle(libraryListStyle)
                .refreshable {
                    viewModel.loadSessions()
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
                    onExport: exportAndShare,
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
                onExport: exportAndShare,
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

    private var libraryListStyle: some ListStyle {
#if os(macOS)
        return SidebarListStyle()
#else
        return InsetGroupedListStyle()
#endif
    }

    private func deleteFilteredSessions(at offsets: IndexSet) {
        let idsToDelete = offsets.compactMap { index in
            filteredSessions.indices.contains(index) ? filteredSessions[index] : nil
        }.map(\.id)
        viewModel.deleteSessions(withIDs: idsToDelete)
    }

    private func exportAndShare(_ session: SavedSession) {
        do {
            let exportURL = try viewModel.exportSession(session)
            #if os(macOS)
            SessionSharePresenter.present(url: exportURL)
            #else
            shareURL = nil
            shareURL = exportURL
            #endif
        } catch {
            #if !os(macOS)
            shareURL = nil
            #endif
            viewModel.exportError = error.localizedDescription
        }
    }
}

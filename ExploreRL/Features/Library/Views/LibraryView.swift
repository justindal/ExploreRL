import SwiftUI

struct LibraryView: View {
    @Binding var externalImportURLs: [URL]
    var onLoad: (SavedSession) -> Void
    var onEvaluate: (SavedSession) -> Void

    @State private var viewModel = LibraryViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility
        .doubleColumn
    @State private var preferredCompactColumn = NavigationSplitViewColumn
        .sidebar
    @State private var selectedSessionID: UUID?
    @State private var showImportPicker = false
    @State private var searchText = ""
    @State private var shareURL: URL?
    @State private var deleteRequest: DeleteRequest?
    @State private var sessionToRename: SavedSession?
    @State private var renameText = ""
    @State private var showFiltersPopover = false
    @State private var draftSortOrder: SortOrder = .dateDesc
    @State private var draftAlgorithmFilters: Set<AlgorithmFilter> = []

    private var groupedSessions: [(envID: String, sessions: [SavedSession])] {
        viewModel.groupedSessions(matching: searchText)
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

    private var hasRenameError: Binding<Bool> {
        Binding(
            get: { viewModel.renameError != nil },
            set: { if !$0 { viewModel.renameError = nil } }
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
        renameAlertView
    }

    private var splitView: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            sidebarContent
        } detail: {
            detailContent
        }
    }

    private var lifecycleView: some View {
        splitView
            .toolbar(removing: .sidebarToggle)
            .onAppear {
                viewModel.loadSessions()
                consumePendingImports()
            }
            .onChange(of: externalImportURLs) { _, _ in
                consumePendingImports()
            }
            .onChange(of: viewModel.sessions) { _, _ in
                if let selectedSessionID,
                    !viewModel.sessions.contains(where: {
                        $0.id == selectedSessionID
                    })
                {
                    self.selectedSessionID = nil
                }
            }
    }

    private var alertsView: some View {
        lifecycleView
            .alert("Delete Failed", isPresented: hasDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.deleteError ?? "")
            }
            .alert("Rename Failed", isPresented: hasRenameError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.renameError ?? "")
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
            .alert(
                "Delete Session?",
                isPresented: Binding(
                    get: { deleteRequest != nil },
                    set: { if !$0 { deleteRequest = nil } }
                ),
                presenting: deleteRequest
            ) { request in
                Button("Delete", role: .destructive) {
                    confirmDelete(request)
                }
                Button("Cancel", role: .cancel) {
                    deleteRequest = nil
                }
            } message: { request in
                Text(
                    "Are you sure you want to delete '\(request.name)'? This will permanently delete this saved session and its trained model."
                )
            }
    }

    @ViewBuilder
    private var shareSheetView: some View {
        #if os(iOS)
        alertsView.sheet(
            isPresented: Binding(
                get: { shareURL != nil },
                set: { if !$0 { shareURL = nil } }
            )
        ) {
            if let shareURL {
                SessionShareSheet(url: shareURL)
                    .presentationDetents([.medium])
            }
        }
        #else
        alertsView
        #endif
    }

    private var importSearchView: some View {
        shareSheetView
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

    private var renameAlertView: some View {
        importSearchView
            .alert(
                "Rename Session",
                isPresented: Binding(
                    get: { sessionToRename != nil },
                    set: {
                        if !$0 {
                            sessionToRename = nil
                            renameText = ""
                        }
                    }
                ),
                presenting: sessionToRename
            ) { session in
                TextField("Session name", text: $renameText)
                Button("Save") {
                    commitRename()
                }
                Button("Cancel", role: .cancel) {
                    sessionToRename = nil
                    renameText = ""
                }
            } message: { session in
                Text("Enter a new name for '\(session.name)'.")
            }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        Group {
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "No Saved Sessions",
                    systemImage: "tray",
                    description: Text(
                        "Train an agent and save your progress to see it here."
                    )
                )
            } else if groupedSessions.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(selection: $selectedSessionID) {
                    ForEach(groupedSessions, id: \.envID) { group in
                        Section(group.envID) {
                            ForEach(group.sessions) { session in
                                NavigationLink(value: session.id) {
                                    SavedSessionRow(session: session)
                                }
                                .swipeActions(
                                    edge: .trailing,
                                    allowsFullSwipe: true
                                ) {
                                    Button(role: .destructive) {
                                        requestDelete(session)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        onLoad(session)
                                    } label: {
                                        Label(
                                            "Load Session",
                                            systemImage: "play.fill"
                                        )
                                    }
                                    Button {
                                        onEvaluate(session)
                                    } label: {
                                        Label(
                                            "Evaluate",
                                            systemImage: "checkmark.circle"
                                        )
                                    }
                                    Button {
                                        beginRenaming(session)
                                    } label: {
                                        Label(
                                            "Rename",
                                            systemImage: "pencil"
                                        )
                                    }
                                    Button {
                                        exportAndShare(session)
                                    } label: {
                                        Label(
                                            "Export",
                                            systemImage: "square.and.arrow.up"
                                        )
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        requestDelete(session)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
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

            ToolbarItem(placement: .automatic) {
                Button {
                    draftSortOrder = viewModel.sortOrder
                    draftAlgorithmFilters = viewModel.algorithmFilters
                    showFiltersPopover = true
                } label: {
                    Image(
                        systemName: viewModel.algorithmFilters.isEmpty
                            ? "line.3.horizontal.decrease.circle"
                            : "line.3.horizontal.decrease.circle.fill"
                    )
                }
                .popover(isPresented: $showFiltersPopover) {
                    LibraryFiltersPopover(
                        sortOrder: $draftSortOrder,
                        algorithmFilters: $draftAlgorithmFilters,
                        onApply: {
                            viewModel.sortOrder = draftSortOrder
                            viewModel.algorithmFilters = draftAlgorithmFilters
                            showFiltersPopover = false
                        }
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
        .navigationDestination(for: UUID.self) { sessionID in
            if let session = viewModel.sessions.first(where: {
                $0.id == sessionID
            }) {
                LibraryDetailView(
                    session: session,
                    onLoad: onLoad,
                    onEvaluate: onEvaluate,
                    onExport: exportAndShare,
                    onRename: beginRenaming,
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
            let session = viewModel.sessions.first(where: {
                $0.id == selectedSessionID
            })
        {
            LibraryDetailView(
                session: session,
                onLoad: onLoad,
                onEvaluate: onEvaluate,
                onExport: exportAndShare,
                onRename: beginRenaming,
                onDelete: { viewModel.delete(session: session) }
            )
        } else if viewModel.sessions.isEmpty {
            ContentUnavailableView(
                "No Saved Sessions",
                systemImage: "tray",
                description: Text(
                    "Train an agent and save your progress to see it here."
                )
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

    private func beginRenaming(_ session: SavedSession) {
        sessionToRename = session
        renameText = session.name
    }

    private func requestDelete(_ session: SavedSession) {
        deleteRequest = DeleteRequest(id: session.id, name: session.name)
    }

    private func confirmDelete(_ request: DeleteRequest) {
        deleteRequest = nil
        guard let session = viewModel.sessions.first(where: { $0.id == request.id }) else {
            return
        }
        viewModel.delete(session: session)
        if session.id == selectedSessionID {
            selectedSessionID = nil
        }
    }

    private func commitRename() {
        guard let session = sessionToRename else { return }
        viewModel.rename(sessionID: session.id, to: renameText)
        sessionToRename = nil
        renameText = ""
    }

    private func consumePendingImports() {
        guard !externalImportURLs.isEmpty else { return }
        let urls = externalImportURLs
        externalImportURLs.removeAll()
        viewModel.importSessions(from: urls)
    }
}

private struct DeleteRequest: Identifiable {
    let id: UUID
    let name: String
}

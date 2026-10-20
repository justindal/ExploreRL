import Gymnazo
import SwiftUI

struct TrainView: View {
    @Bindable var viewModel: TrainViewModel
    @State private var loadError: String?
    @State private var isLoadingSession = false
    @State private var searchText = ""
    @Binding var envSpecs: [EnvSpec]
    @Binding var sessionToLoad: SavedSession?
    @Binding var navigation: TrainNavigation
    var showSettingsInspector: Binding<Bool>? = nil

    private var sections: [(category: EnvCategory, items: [EnvSpec])] {
        EnvCategory.allCases.compactMap { category in
            let items = envSpecs.filter {
                $0.category == category && $0.matchesSearch(searchText)
            }
            return items.isEmpty ? nil : (category, items)
        }
    }

    #if os(macOS)
        var body: some View {
            NavigationSplitView {
                envList
                    .listStyle(.sidebar)
                    .navigationTitle("Environments")
                    .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            } detail: {
                if isLoadingSession {
                    ProgressView("Loading session...")
                } else if let envID = navigation.selectedEnvironmentID {
                    TrainDetailView(id: envID, vm: viewModel)
                } else {
                    ContentUnavailableView(
                        "Select an Environment",
                        systemImage: "square.grid.2x2",
                        description: Text(
                            "Choose an environment from the sidebar to start training.")
                    )
                }
            }
            .onChange(of: sessionToLoad, initial: true) { _, newSession in
                handleSessionLoad(newSession)
            }
            .alert("Load Failed", isPresented: loadFailedBinding) {
                Button("OK") { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    #else
        var body: some View {
            Group {
                if let showSettingsInspector {
                    if isLoadingSession {
                        ProgressView("Loading session...")
                    } else if let id = navigation.selectedEnvironmentID {
                        TrainDetailView(
                            id: id, vm: viewModel,
                            showSettingsInspector: showSettingsInspector
                        )
                    } else {
                        ContentUnavailableView(
                            "Select an Environment",
                            systemImage: "square.grid.2x2",
                            description: Text("Choose an environment from the sidebar to start training.")
                        )
                        .navigationTitle("Train")
                    }
                } else {
                    NavigationStack(path: $navigation.path) {
                        envList
                            .listStyle(.insetGrouped)
                            .navigationTitle("Train")
                            .navigationDestination(for: String.self) { envID in
                                TrainDetailView(id: envID, vm: viewModel)
                            }
                    }
                }
            }
            .onChange(of: sessionToLoad, initial: true) { _, newSession in
                handleSessionLoad(newSession)
            }
            .alert("Load Failed", isPresented: loadFailedBinding) {
                Button("OK") { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }

    #endif

    private var envList: some View {
        Group {
            if sections.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if usesSplitLayout {
                List(selection: $navigation.selectedEnvironmentID) {
                    environmentRows
                }
            } else {
                List {
                    environmentRows
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search environments")
    }

    @ViewBuilder
    private var environmentRows: some View {
        ForEach(sections, id: \.category) { section in
            Section(section.category.rawValue) {
                ForEach(section.items, id: \.id) { spec in
                    #if os(macOS)
                        TrainListRow(
                            name: spec.displayName ?? spec.name,
                            description: spec.description ?? "",
                            algorithms: [],
                            status: viewModel.trainingState(for: spec.id).status
                        )
                        .tag(spec.id)
                    #else
                        NavigationLink(value: spec.id) {
                            TrainListRow(
                                name: spec.displayName ?? spec.name,
                                description: spec.description ?? "",
                                algorithms: [],
                                status: viewModel.trainingState(for: spec.id).status
                            )
                        }
                    #endif
                }
            }
        }
    }

    private var usesSplitLayout: Bool {
        #if os(macOS)
            true
        #else
            false
        #endif
    }

    private var loadFailedBinding: Binding<Bool> {
        .init(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )
    }

    private func handleSessionLoad(_ session: SavedSession?) {
        guard let session else { return }
        sessionToLoad = nil
        isLoadingSession = true
        Task {
            do {
                try await viewModel.loadSession(session)
                navigation.selectedEnvironmentID = session.environmentID
            } catch {
                loadError = error.localizedDescription
            }
            isLoadingSession = false
        }
    }
}

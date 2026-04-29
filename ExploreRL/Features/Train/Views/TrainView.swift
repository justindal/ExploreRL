import Gymnazo
import SwiftUI

struct TrainView: View {
    @State private var viewModel = TrainViewModel()
    @State private var loadError: String?
    @State private var isLoadingSession = false
    @Binding var envSpecs: [EnvSpec]
    @Binding var sessionToLoad: SavedSession?

    private var sections: [(category: EnvCategory, items: [EnvSpec])] {
        EnvCategory.allCases.compactMap { category in
            let items = envSpecs.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    #if os(macOS)
        @State private var selectedEnvID: String?

        var body: some View {
            NavigationSplitView {
                envList
                    .listStyle(.sidebar)
                    .navigationTitle("Environments")
                    .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            } detail: {
                if isLoadingSession {
                    ProgressView("Loading session...")
                } else if let envID = selectedEnvID {
                    TrainDetailView(id: envID, vm: viewModel)
                } else {
                    ContentUnavailableView(
                        "Select an Environment",
                        systemImage: "square.grid.2x2",
                        description: Text("Choose an environment from the sidebar to start training.")
                    )
                }
            }
            .onChange(of: sessionToLoad) { _, newSession in
                handleSessionLoad(newSession)
            }
            .alert("Load Failed", isPresented: loadFailedBinding) {
                Button("OK") { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    #else
        @State private var path: [String] = []

        var body: some View {
            NavigationStack(path: $path) {
                envList
                    .listStyle(.insetGrouped)
                    .navigationTitle("Train")
                    .navigationDestination(for: String.self) { envID in
                        TrainDetailView(id: envID, vm: viewModel)
                    }
            }
            .onChange(of: sessionToLoad) { _, newSession in
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
        List {
            ForEach(sections, id: \.category) { section in
                Section(section.category.rawValue) {
                    ForEach(section.items, id: \.id) { spec in
                        #if os(macOS)
                            TrainListRow(
                                name: spec.displayName ?? spec.name,
                                description: spec.description ?? "",
                                algorithms: [],
                                isTraining: viewModel.trainingState(for: spec.id).status == .training
                            )
                            .tag(spec.id)
                        #else
                            NavigationLink(value: spec.id) {
                                TrainListRow(
                                    name: spec.displayName ?? spec.name,
                                    description: spec.description ?? "",
                                    algorithms: [],
                                    isTraining: viewModel.trainingState(for: spec.id).status == .training
                                )
                            }
                        #endif
                    }
                }
            }
        }
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
                #if os(macOS)
                    selectedEnvID = session.environmentID
                #else
                    path = [session.environmentID]
                #endif
            } catch {
                loadError = error.localizedDescription
            }
            isLoadingSession = false
        }
    }
}

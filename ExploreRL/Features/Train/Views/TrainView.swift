//
//  TrainView.swift
//  ExploreRL
//

import Gymnazo
import SwiftUI

struct TrainView: View {
    @State private var viewModel = TrainViewModel()
    @State private var selectedEnvID: String?
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

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedEnvID) {
                ForEach(sections, id: \.category) { section in
                    Section(section.category.rawValue) {
                        ForEach(section.items, id: \.id) { spec in
                            TrainListRow(
                                name: spec.displayName ?? spec.name,
                                description: spec.description ?? "",
                                algorithms: [],
                                isTraining: viewModel.trainingState(for: spec.id).status == .training
                            )
                            .tag(spec.id)
                        }
                    }
                }
            }
            .listStyle(trainListStyle)
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
                    systemImage: "square.grid.2x2"
                )
            }
        }
        .onChange(of: sessionToLoad) { _, newSession in
            guard let session = newSession else { return }
            sessionToLoad = nil
            selectedEnvID = nil
            isLoadingSession = true
            Task {
                do {
                    try await viewModel.loadSession(session)
                    selectedEnvID = session.environmentID
                } catch {
                    loadError = error.localizedDescription
                }
                isLoadingSession = false
            }
        }
        .alert("Load Failed", isPresented: .init(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("OK") { loadError = nil }
        } message: {
            Text(loadError ?? "")
        }
    }

    private var trainListStyle: some ListStyle {
        #if os(macOS)
        SidebarListStyle()
        #else
        InsetGroupedListStyle()
        #endif
    }
}

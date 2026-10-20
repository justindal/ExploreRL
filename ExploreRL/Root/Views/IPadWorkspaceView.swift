import Gymnazo
import SwiftUI

struct IPadWorkspaceView<Detail: View>: View {
    @Bindable var trainViewModel: TrainViewModel
    @Binding var selectedTab: AppTab
    @Binding var navigation: TrainNavigation
    let envSpecs: [EnvSpec]
    let showExplore: Bool
    @ViewBuilder let detail: Detail
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            List(selection: selection) {
                Section("App") {
                    ForEach(AppTab.allCases.filter { showExplore || $0 != .explore }) { tab in
                        Label(tab.rawValue, systemImage: tab.symbol)
                            .tag(IPadDestination.tab(tab))
                    }
                }

                ForEach(EnvCategory.allCases, id: \.self) { category in
                    let specs = envSpecs.filter {
                        $0.category == category && $0.matchesSearch(searchText)
                    }
                    if !specs.isEmpty {
                        Section(category.rawValue) {
                            ForEach(specs, id: \.id) { spec in
                                TrainListRow(
                                    name: spec.displayName ?? spec.name,
                                    description: spec.description ?? "",
                                    algorithms: [],
                                    status: trainViewModel.trainingState(for: spec.id).status
                                )
                                .tag(IPadDestination.environment(spec.id))
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ExploreRL")
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 380)
            .searchable(text: $searchText, placement: .sidebar, prompt: "Search environments")
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var selection: Binding<IPadDestination?> {
        Binding(
            get: {
                IPadDestination(tab: selectedTab, environmentID: navigation.selectedEnvironmentID)
            },
            set: { destination in
                guard let destination else { return }
                selectedTab = destination.tab
                if case .environment(let id) = destination {
                    navigation.selectedEnvironmentID = id
                }
            }
        )
    }
}

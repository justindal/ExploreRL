import SwiftUI

struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var searchText = ""

    private var filteredSections: [(section: ExploreSection, items: [ExploreItem])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ExploreSection.allCases.compactMap { section in
            let items = query.isEmpty
                ? section.items
                : section.items.filter {
                    $0.title.lowercased().contains(query)
                        || $0.subtitle.lowercased().contains(query)
                }
            return items.isEmpty ? nil : (section, items)
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            sidebar(selection: $viewModel.selection)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            detail(selection: viewModel.selection)
        }
        .toolbar(removing: .sidebarToggle)
    }

    private func row(for item: ExploreItem) -> some View {
        ExploreItemRow(item: item)
            .tag(item)
            .modify { view in
                #if os(iOS)
                view.listRowSeparator(.hidden)
                #else
                view
                #endif
            }
    }

    private func sidebar(selection: Binding<ExploreItem?>) -> some View {
        List(selection: selection) {
            ForEach(filteredSections, id: \.section) { entry in
                Section(entry.section.title) {
                    ForEach(entry.items) { item in
                        row(for: item)
                    }
                }
            }
        }
        .modify { view in
            if #available(iOS 26.0, *), #available(macOS 26.0, *) {
                view.scrollEdgeEffectStyle(.hard, for: .top)
            }
        }
        .listStyle(exploreListStyle)
        .navigationTitle("Explore")
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search topics")
    }

    @ViewBuilder
    private func detail(selection: ExploreItem?) -> some View {
        if let selection {
            ExploreItemDetailView(item: selection)
        } else {
            ContentUnavailableView(
                "Select a Topic",
                systemImage: "book.closed",
                description: Text("Explore RL algorithms and environments.")
            )
        }
    }
    
    private var exploreListStyle: some ListStyle {
        #if os(macOS)
        return SidebarListStyle()
        #else
        return InsetGroupedListStyle()
        #endif
    }
}

#Preview {
    ExploreView()
}

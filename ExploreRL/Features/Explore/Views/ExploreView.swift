import SwiftUI

struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    @State private var searchText = ""
    @SceneStorage("exploreTopic") private var storedTopic: String?

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

    private var exploreDetail: some View {
        Group {
            if let selection = viewModel.selection {
                ExploreItemDetailView(item: selection)
                    .navigationTitle(selection.title)
            } else {
                ContentUnavailableView(
                    "Select a Topic",
                    systemImage: "book.closed",
                    description: Text("Explore RL algorithms and environments.")
                )
                .navigationTitle("Explore")
            }
        }
    }

    var body: some View {
        #if os(iOS)
        iosLayout
        #else
        macLayout
        #endif
    }

    #if os(iOS)
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar

    private var iosLayout: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            topicList
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            exploreDetail
        }
        .onChange(of: viewModel.selection) { _, newSelection in
            preferredCompactColumn = newSelection == nil ? .sidebar : .detail
        }
    }
    #endif

    #if os(macOS)
    private var macLayout: some View {
        HStack(spacing: 0) {
            topicList
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)

            Divider()

            NavigationStack {
                exploreDetail
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    #endif

    private var topicList: some View {
        @Bindable var vm = viewModel
        return List(selection: $vm.selection) {
            ForEach(filteredSections, id: \.section) { entry in
                Section(entry.section.title) {
                    ForEach(entry.items) { item in
                        ExploreItemRow(item: item)
                            .tag(item)
                            #if os(iOS)
                            .listRowSeparator(.hidden)
                            #endif
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
        .searchable(text: $searchText, prompt: "Search topics")
        .onAppear {
            restoreTopic()
        }
        .onChange(of: viewModel.selection) { _, newValue in
            storedTopic = newValue?.rawValue
        }
    }

    private var exploreListStyle: some ListStyle {
        #if os(macOS)
        SidebarListStyle()
        #else
        InsetGroupedListStyle()
        #endif
    }

    private func restoreTopic() {
        guard let raw = storedTopic, let item = ExploreItem(rawValue: raw) else { return }
        viewModel.selection = item
    }
}

#Preview {
    ExploreView()
}

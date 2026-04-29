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

    var body: some View {
        #if os(iOS)
        iosLayout
        #else
        macLayout
        #endif
    }

    #if os(iOS)
    private var iosLayout: some View {
        NavigationStack {
            topicList
                .navigationTitle("Explore")
                .navigationDestination(for: ExploreItem.self) { item in
                    ExploreItemDetailView(item: item)
                        .navigationTitle(item.title)
                }
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
    #endif

    private var topicList: some View {
        #if os(macOS)
        @Bindable var vm = viewModel
        return listContent
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "Search topics")
            .onAppear { restoreTopic() }
            .onChange(of: viewModel.selection) { _, newValue in
                storedTopic = newValue?.rawValue
            }
        #else
        return listContent
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search topics")
            .onAppear { restoreTopic() }
            .onChange(of: viewModel.selection) { _, newValue in
                storedTopic = newValue?.rawValue
            }
        #endif
    }

    private var listContent: some View {
        #if os(macOS)
        @Bindable var vm = viewModel
        return List(selection: $vm.selection) {
            ForEach(filteredSections, id: \.section) { entry in
                Section(entry.section.title) {
                    ForEach(entry.items) { item in
                        ExploreItemRow(item: item)
                            .tag(item)
                    }
                }
            }
        }
        .modify { view in
            if #available(iOS 26.0, *), #available(macOS 26.0, *) {
                view.scrollEdgeEffectStyle(.hard, for: .top)
            }
        }
        #else
        return List {
            ForEach(filteredSections, id: \.section) { entry in
                Section(entry.section.title) {
                    ForEach(entry.items) { item in
                        NavigationLink(value: item) {
                            ExploreItemRow(item: item)
                        }
                    }
                }
            }
        }
        .modify { view in
            if #available(iOS 26.0, *), #available(macOS 26.0, *) {
                view.scrollEdgeEffectStyle(.hard, for: .top)
            }
        }
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

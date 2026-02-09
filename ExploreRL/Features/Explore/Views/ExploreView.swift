import SwiftUI

struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            sidebar(selection: $viewModel.selection)
        } detail: {
            detail(selection: viewModel.selection)
        }
        .toolbar(removing: .sidebarToggle)
    }

    private func row(for item: ExploreItem) -> some View {
        ExploreItemRow(item: item)
            .tag(item)
            .listRowInsets(
                EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private func sidebar(selection: Binding<ExploreItem?>) -> some View {
        List(selection: selection) {
            ForEach(ExploreSection.allCases) { section in
                if section == .environments {
                    Section {
                        ForEach(section.items) { item in
                            row(for: item)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Toy Text, Classic Control, Box2D")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .textCase(nil)
                        .padding(.top, 6)
                    }
                } else {
                    Section(section.title) {
                        ForEach(section.items) { item in
                            row(for: item)
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Explore")
    }

    @ViewBuilder
    private func detail(selection: ExploreItem?) -> some View {
        if let selection {
            ExploreItemDetailView(item: selection)
        } else {
            VStack(spacing: 12) {
                Text("Select a topic")
                    .font(.title3.weight(.semibold))
                Text(
                    "Reinforcement learning concepts, algorithms, and environments."
                )
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

#Preview {
    ExploreView()
}

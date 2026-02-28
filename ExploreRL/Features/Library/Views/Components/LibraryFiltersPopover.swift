import SwiftUI

struct LibraryFiltersPopover: View {
    @Binding var sortOrder: SortOrder
    @Binding var algorithmFilters: Set<AlgorithmFilter>
    var onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Sort By", selection: $sortOrder) {
                ForEach(SortOrder.allCases) { order in
                    Text(order.rawValue).tag(order)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Filter Algorithms")
                    .font(.headline)

                ForEach(AlgorithmFilter.allCases) { filter in
                    Toggle(filter.rawValue, isOn: algorithmBinding(for: filter))
                }
            }

            HStack {
                Button("Reset Filters") {
                    algorithmFilters.removeAll()
                }
                .disabled(algorithmFilters.isEmpty)

                Spacer()

                Button("Apply") {
                    onApply()
                }
            }
        }
        .padding(16)
        .frame(minWidth: 260)
    }

    private func algorithmBinding(for filter: AlgorithmFilter) -> Binding<Bool> {
        Binding(
            get: { algorithmFilters.contains(filter) },
            set: { isEnabled in
                if isEnabled {
                    algorithmFilters.insert(filter)
                } else {
                    algorithmFilters.remove(filter)
                }
            }
        )
    }
}

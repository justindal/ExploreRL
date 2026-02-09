import SwiftUI

struct QTableView: View {
    let states: [String]
    let actions: [String]
    let values: [[Double]]
    let highlightedCell: (row: Int, col: Int)?

    init(
        states: [String],
        actions: [String],
        values: [[Double]],
        highlightedCell: (row: Int, col: Int)? = nil
    ) {
        self.states = states
        self.actions = actions
        self.values = values
        self.highlightedCell = highlightedCell
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            ForEach(Array(states.enumerated()), id: \.offset) { rowIndex, state in
                dataRow(state: state, rowIndex: rowIndex)
            }
        }
        .font(.system(.caption, design: .monospaced))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("State")
                .frame(width: 60, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            ForEach(actions, id: \.self) { action in
                Text(action)
                    .frame(width: 50)
                    .padding(.vertical, 6)
            }
        }
        .background(.thinMaterial)
    }

    private func dataRow(state: String, rowIndex: Int) -> some View {
        HStack(spacing: 0) {
            Text(state)
                .frame(width: 60, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            ForEach(Array(actions.enumerated()), id: \.offset) { colIndex, _ in
                let isHighlighted = highlightedCell?.row == rowIndex && highlightedCell?.col == colIndex
                let value = values[rowIndex][colIndex]

                Text(String(format: "%.2f", value))
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(isHighlighted ? Color.accentColor.opacity(0.3) : Color.clear)
                    .foregroundStyle(value > 0 ? .primary : .secondary)
            }
        }
    }
}

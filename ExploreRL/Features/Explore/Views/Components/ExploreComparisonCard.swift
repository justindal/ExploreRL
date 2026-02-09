import SwiftUI

struct ExploreComparison: Identifiable, Hashable {
    let aspect: String
    let left: String
    let right: String

    var id: String { aspect }
}

struct ExploreComparisonCard: View {
    let title: String
    let leftTitle: String
    let rightTitle: String
    let rows: [ExploreComparison]
    let footer: String?

    init(
        title: String,
        leftTitle: String,
        rightTitle: String,
        rows: [ExploreComparison],
        footer: String? = nil
    ) {
        self.title = title
        self.leftTitle = leftTitle
        self.rightTitle = rightTitle
        self.rows = rows
        self.footer = footer
    }

    var body: some View {
        ExploreSectionCard(title: title) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(rows) { row in
                    ExploreComparisonRow(
                        aspect: row.aspect,
                        leftTitle: leftTitle,
                        left: row.left,
                        rightTitle: rightTitle,
                        right: row.right
                    )
                }

                if let footer {
                    Text(footer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }
}

private struct ExploreComparisonRow: View {
    let aspect: String
    let leftTitle: String
    let left: String
    let rightTitle: String
    let right: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(aspect).fontWeight(.medium)
            HStack(alignment: .top, spacing: 16) {
                HStack(alignment: .top, spacing: 4) {
                    Text("\(leftTitle):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(left)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 4) {
                    Text("\(rightTitle):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(right)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}


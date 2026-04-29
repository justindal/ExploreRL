import SwiftUI

struct ExploreItemRow: View {
    let item: ExploreItem

    private func envTint(_ kind: EnvKind) -> Color {
        switch kind {
        case .toyText: .orange
        case .classicControl: .teal
        case .box2D: .pink
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.title)
                .font(.body.weight(.semibold))
                .lineLimit(1)

            Text(item.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            let algos = item.suggestedAlgorithms
            if let kind = item.environmentKind {
                HStack(spacing: 6) {
                    ExploreKindBadge(text: kind.title, tint: envTint(kind))
                    ForEach(algos, id: \.self) { a in
                        AlgorithmBadge(text: a)
                    }
                }
                .padding(.top, 2)
            } else if !algos.isEmpty {
                HStack(spacing: 6) {
                    ForEach(algos, id: \.self) { a in
                        AlgorithmBadge(text: a)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

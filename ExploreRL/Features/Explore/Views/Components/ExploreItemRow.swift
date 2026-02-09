import SwiftUI

struct ExploreItemRow: View {
    let item: ExploreItem

    private var accent: Color {
        if let kind = item.environmentKind {
            return envTint(kind)
        }
        switch item {
        case .rlLoop, .returns, .exploration, .replay, .neuralNetworks, .activationFunctions, .optimizers:
            return .purple
        case .qLearning, .sarsa, .dqn, .sac:
            return .blue
        default:
            return .secondary
        }
    }

    private func envTint(_ kind: EnvKind) -> Color {
        switch kind {
        case .toyText: .orange
        case .classicControl: .teal
        case .box2D: .pink
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

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
                } else if !algos.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(algos, id: \.self) { a in
                            AlgorithmBadge(text: a)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

import SwiftUI

struct ExploreParameter: Identifiable, Hashable {
    let name: String
    let typical: String
    let description: String

    var id: String { name }
}

struct ExploreParametersCard: View {
    let title: String
    let parameters: [ExploreParameter]

    var body: some View {
        ExploreSectionCard(title: title) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(parameters) { parameter in
                    ExploreParameterRow(parameter: parameter)
                }
            }
        }
    }
}

private struct ExploreParameterRow: View {
    let parameter: ExploreParameter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(parameter.name).fontWeight(.medium)
                Spacer()
                Text(parameter.typical)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            Text(parameter.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}


import SwiftUI

struct EvaluationResults: View {
    let state: EvaluationState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Episode Results")
                .font(.headline)
            episodesSection
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#").frame(width: 40, alignment: .leading)
                Text("Reward").frame(maxWidth: .infinity, alignment: .leading)
                Text("Length").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)

            ForEach(Array(state.episodeRewards.enumerated()), id: \.offset) { index, reward in
                HStack {
                    Text("\(index + 1)")
                        .frame(width: 40, alignment: .leading)
                        .foregroundStyle(.secondary)

                    Text(String(format: "%.2f", reward))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if index < state.episodeLengths.count {
                        Text("\(state.episodeLengths[index])")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Spacer()
                    }
                }
                .font(.subheadline.monospacedDigit())
                .padding(.horizontal, 4)
                .padding(.vertical, 6)

                if index < state.episodeRewards.count - 1 {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
    }

}

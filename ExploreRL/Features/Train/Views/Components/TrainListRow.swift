//
//  TrainListRow.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-02.
//

import SwiftUI

struct TrainListRow: View {

    let name: String
    let description: String
    let algorithms: [String]
    var isTraining: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                if !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !algorithms.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(algorithms, id: \.self) { alg in
                            AlgorithmBadge(text: alg)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            #if os(macOS)
            if isTraining {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, isActive: true)
            }
            #endif

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TrainListRow(
        name: "CartPole",
        description:
            "Balance a pole on a moving cart by applying left or right forces.",
        algorithms: ["DQN", "IDK"]
    )
}

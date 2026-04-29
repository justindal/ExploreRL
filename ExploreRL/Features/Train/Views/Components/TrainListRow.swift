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
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .bold()
                    .lineLimit(1)

                if !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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

            if isTraining {
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, isActive: true)
            }
        }
        .padding(.vertical, 2)
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

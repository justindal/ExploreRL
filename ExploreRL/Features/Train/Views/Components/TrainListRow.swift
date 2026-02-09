//
//  TrainListRow.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-02.
//

import SwiftUI

struct TrainListRow: View {

    let iconName: String = "brain"
    let name: String
    let description: String
    let algorithms: [String]

    var body: some View {
        HStack(alignment: .center, spacing: 16) {

            ZStack {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(Color.indigo.opacity(0.9))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 25))

            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                HStack(spacing: 5) {
                    ForEach(algorithms, id: \.self) { alg in
                        AlgorithmBadge(text: alg)
                    }
                }
                .padding(.top, 4)

            }
            
            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            .ultraThinMaterial
                .shadow(
                    .drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5)
                )
                .shadow(
                    .drop(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        

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

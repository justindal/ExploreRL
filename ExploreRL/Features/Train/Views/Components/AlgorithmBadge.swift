//
//  AlgorithmBadge.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-02.
//

import SwiftUI

struct AlgorithmBadge: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.quaternary.opacity(0.35), in: Capsule())
    }
}

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
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
            )
    }
}

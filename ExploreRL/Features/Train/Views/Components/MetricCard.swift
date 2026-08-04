//
//  MetricCard.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-04.
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .bold()
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppLayout.compactSpacing)
        .accessibilityElement(children: .combine)
    }
}

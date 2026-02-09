//
//  View+modify.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-03.
//

import SwiftUI

extension View {
    @ViewBuilder
    func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content)
        -> some View
    {
        transform(self)
    }

    @ViewBuilder
    func modify(
        if condition: Bool,
        @ViewBuilder _ transform: (Self) -> some View
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

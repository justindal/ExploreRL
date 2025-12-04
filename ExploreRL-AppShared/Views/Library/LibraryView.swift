//
//  LibraryView.swift
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        #if os(macOS)
        LibraryContentView()
        #else
        if horizontalSizeClass == .compact {
            LibraryStackView()
        } else {
            LibraryContentView()
        }
        #endif
    }
}

#Preview {
    LibraryView()
}


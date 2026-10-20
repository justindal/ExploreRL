//
//  OnboardingView.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-03-21.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentIndex: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let pages: [OnboardingItem]
    let onFinish: () -> Void

    init(
        pages: [OnboardingItem],
        initialIndex: Int = 0,
        onFinish: @escaping () -> Void = {}
    ) {
        self.pages = pages
        self.onFinish = onFinish
        _currentIndex = State(initialValue: initialIndex)
    }

    private var currentPage: OnboardingItem? {
        guard pages.indices.contains(currentIndex) else {
            return nil
        }
        return pages[currentIndex]
    }

    private var showsImage: Bool {
        currentPage?.imageName != nil
    }

    var body: some View {

        ScrollView {
            VStack(spacing: 24) {
                if showsImage {
                    OnboardingImage(pages: pages, currentIndex: currentIndex)
                        .frame(height: dynamicTypeSize.isAccessibilitySize ? 120 : 300)
                        .padding(.horizontal, 24)
                        .accessibilityHidden(true)
                }
                OnboardingTexts(pages: pages, currentIndex: currentIndex)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .id(currentIndex)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                Indicator(currentIndex: currentIndex, count: pages.count)
                    .accessibilityLabel("Page \(currentIndex + 1) of \(pages.count)")
                ActionRow(
                    currentIndex: $currentIndex,
                    pageCount: pages.count,
                    onFinish: onFinish
                )
            }
            .padding(.vertical, 8)
            .background(.bar)
        }

    }

}

#Preview {
    OnboardingView(pages: OnboardingItem.pages)
}

#Preview("Page 2") {
    OnboardingView(pages: OnboardingItem.pages, initialIndex: 1)
}

#Preview("Last Page") {
    OnboardingView(
        pages: OnboardingItem.pages,
        initialIndex: OnboardingItem.pages.count - 1
    )
}

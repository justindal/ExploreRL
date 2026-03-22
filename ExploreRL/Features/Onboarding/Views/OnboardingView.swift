//
//  OnboardingView.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-03-21.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentIndex: Int
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

        VStack(spacing: 0) {
            if showsImage {
                OnboardingImage(pages: pages, currentIndex: currentIndex)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 14)

                OnboardingTexts(pages: pages, currentIndex: currentIndex)
                    .padding(.bottom, 8)
            } else {
                Spacer(minLength: 0)
                OnboardingTexts(pages: pages, currentIndex: currentIndex)
                    .padding(.bottom, 28)
                Spacer(minLength: 0)
            }

            Indicator(currentIndex: currentIndex, count: pages.count)
                .padding(.bottom, 8)
            ActionRow(
                currentIndex: $currentIndex,
                pageCount: pages.count,
                onFinish: onFinish
            )
        }
        .animation(.easeInOut(duration: 0.25), value: showsImage)
        .padding(.bottom, 8)

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

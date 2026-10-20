import SwiftUI

struct OnboardingTexts: View {
    let pages: [OnboardingItem]
    let currentIndex: Int

    var body: some View {
        if pages.indices.contains(currentIndex) {
            let page = pages[currentIndex]
            VStack(spacing: 8) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(page.subtitle)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 100)
        }
    }
}

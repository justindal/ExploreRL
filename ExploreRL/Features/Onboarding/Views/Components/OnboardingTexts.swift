import SwiftUI

struct OnboardingTexts: View {
    let pages: [OnboardingItem]
    let currentIndex: Int

    var body: some View {
        ZStack {
            ForEach(pages.indices, id: \.self) { index in
                let page = pages[index]
                let isActive = currentIndex == index

                VStack(spacing: 8) {
                    Text(page.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text(page.subtitle)
                        .font(.callout)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .compositingGroup()
                .blur(radius: isActive ? 0 : 20)
                .opacity(isActive ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}

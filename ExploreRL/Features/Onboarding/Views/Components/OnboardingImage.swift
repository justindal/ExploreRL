import SwiftUI

struct OnboardingImage: View {
    let pages: [OnboardingItem]
    let currentIndex: Int

    var body: some View {
        ZStack {
            ForEach(pages.indices, id: \.self) { index in
                let page = pages[index]
                let isActive = currentIndex == index

                Group {
                    if let imageName = page.imageName {
                        switch page.imageStyle {
                        case .card:
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(page.zoomScale, anchor: page.zoomAnchor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .icon:
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(page.zoomScale, anchor: page.zoomAnchor)
                                .frame(maxWidth: 180, maxHeight: 180)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .compositingGroup()
                .blur(radius: isActive ? 0 : 20)
                .opacity(isActive ? 1 : 0)
            }
        }
    }
}

import SwiftUI

enum OnboardingImageStyle {
    case card
    case icon
}

struct OnboardingItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let imageName: String?
    let imageStyle: OnboardingImageStyle
    let zoomScale: CGFloat
    let zoomAnchor: UnitPoint

    init(
        id: Int,
        title: String,
        subtitle: String,
        imageName: String? = nil,
        imageStyle: OnboardingImageStyle = .card,
        zoomScale: CGFloat = 1,
        zoomAnchor: UnitPoint = .center
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.imageStyle = imageStyle
        self.zoomScale = zoomScale
        self.zoomAnchor = zoomAnchor
    }
}

extension OnboardingItem {
    static let pages: [OnboardingItem] = [
        OnboardingItem(
            id: 0,
            title: "Welcome to ExploreRL",
            subtitle: "Learn reinforcement learning by training and evaluating agents on-device.",
            imageName: "ExploreRLIcon-iOS-Default-512x512",
            imageStyle: .icon
        ),
        OnboardingItem(
            id: 1,
            title: "Train in a few steps",
            subtitle: "Choose an environment and algorithm, tune settings, then start training.",
            imageName: "ios-train"
        ),
        OnboardingItem(
            id: 2,
            title: "Track progress live",
            subtitle: "Follow reward and episode trends as your agent improves over time.",
            imageName: "ios-track"
        ),
        OnboardingItem(
            id: 3,
            title: "Save, import, and export",
            subtitle: "Keep sessions in Library, export them to share, and import sessions from other devices.",
            imageName: "ios-library"
        ),
        OnboardingItem(
            id: 4,
            title: "Learn the concepts",
            subtitle: "Use Explore to understand RL fundamentals, algorithms, and environments. Disable the tab in Settings if you are experienced!",
            imageName: "ios-learn"
        ),
        OnboardingItem(
            id: 5,
            title: "All done",
            subtitle: "Start in Train to run your first agent. Need a refresher later? Open Settings to run onboarding again."
        )
    ]
}

import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case library = "Library"
    case train = "Train"
    case evaluate = "Evaluate"
    case explore = "Explore"
    case settings = "Settings"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .home: "house"
        case .library: "books.vertical"
        case .train: "brain"
        case .evaluate: "play.circle"
        case .explore: "graduationcap"
        case .settings: "gear"
        }
    }
}

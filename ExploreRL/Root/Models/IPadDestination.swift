enum IPadDestination: Hashable {
    case tab(AppTab)
    case environment(String)

    init(tab: AppTab, environmentID: String?) {
        if tab == .train, let environmentID {
            self = .environment(environmentID)
        } else {
            self = .tab(tab)
        }
    }

    var tab: AppTab {
        switch self {
        case .tab(let tab): tab
        case .environment: .train
        }
    }
}

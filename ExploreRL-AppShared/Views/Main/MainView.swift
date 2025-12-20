//
//  MainView.swift
//

import SwiftUI

enum NavItem: Hashable {
    case library
    case train(EnvironmentType)
    case evaluate
    case explore
}

struct MainView: View {
    private var trainingState = TrainingState.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    @State private var frozenLakeRunner = FrozenLakeRunner()
    @State private var blackjackRunner = BlackjackRunner()
    @State private var taxiRunner = TaxiRunner()
    @State private var cliffWalkingRunner = CliffWalkingRunner()
    @State private var cartPoleRunner = CartPoleRunner()
    @State private var mountainCarRunner = MountainCarRunner()
    @State private var mountainCarContinuousRunner = MountainCarContinuousRunner()
    @State private var acrobotRunner = AcrobotRunner()
    @State private var pendulumRunner = PendulumRunner()
    @State private var lunarLanderRunner = LunarLanderRunner()
    @State private var lunarLanderContinuousRunner = LunarLanderContinuousRunner()
    @State private var evaluationRunner = EvaluationRunner()
    
    @State private var selectedItem: NavItem? = .library
    @State private var toyTextExpanded = true
    @State private var classicControlExpanded = true
    @State private var box2dExpanded = true
    @State private var atariExpanded = true
    @State private var mujocoExpanded = true
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    private func expansionBinding(for category: EnvironmentCategory) -> Binding<Bool> {
        switch category {
        case .toyText:
            return $toyTextExpanded
        case .classicControl:
            return $classicControlExpanded
        case .box2d:
            return $box2dExpanded
        case .atari:
            return $atariExpanded
        case .mujoco:
            return $mujocoExpanded
        }
    }
    
    var body: some View {
        if isCompact {
            iPhoneTabView
        } else {
            sidebarView
        }
    }
    
    private var sidebarView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedItem) {
                NavigationLink(value: NavItem.library) {
                    Label("Library", systemImage: "books.vertical")
                }
                
                NavigationLink(value: NavItem.explore) {
                    Label("Explore", systemImage: "sparkle.magnifyingglass")
                }
                
                NavigationLink(value: NavItem.evaluate) {
                    Label("Evaluate", systemImage: "play.circle")
                }
                
                Section("Train") {
                    ForEach(EnvironmentRegistry.groupedEnvironments, id: \.category) { group in
                        DisclosureGroup(isExpanded: expansionBinding(for: group.category)) {
                            ForEach(group.environments) { envInfo in
                                NavigationLink(value: NavItem.train(envInfo.type)) {
                                    Label(envInfo.displayName, systemImage: envInfo.icon)
                                }
                                .disabled(trainingState.isTraining && trainingState.activeEnvironment != envInfo.displayName)
                            }
                        } label: {
                            Text(group.category.rawValue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("ExploreRL")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
            #endif
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .library:
            LibraryView()
        case .explore:
            ExploreView()
                .navigationTitle("Explore")
        case .train(let envType):
            trainView(for: envType)
        case .evaluate:
            EvaluateView(runner: evaluationRunner)
        case nil:
            ContentUnavailableView("Select an Item", systemImage: "sidebar.left", description: Text("Choose something from the sidebar"))
        }
    }
    
    private var iPhoneTabView: some View {
        TabView {
            Tab("Library", systemImage: "books.vertical") {
                LibraryView()
            }
            
            Tab("Train", systemImage: "graduationcap") {
                TrainLandingView(
                    frozenLakeRunner: frozenLakeRunner,
                    blackjackRunner: blackjackRunner,
                    taxiRunner: taxiRunner,
                    cliffWalkingRunner: cliffWalkingRunner,
                    cartPoleRunner: cartPoleRunner,
                    mountainCarRunner: mountainCarRunner,
                    mountainCarContinuousRunner: mountainCarContinuousRunner,
                    acrobotRunner: acrobotRunner,
                    pendulumRunner: pendulumRunner,
                    lunarLanderRunner: lunarLanderRunner,
                    lunarLanderContinuousRunner: lunarLanderContinuousRunner
                )
            }
            
            Tab("Evaluate", systemImage: "play.circle") {
                EvaluateView(runner: evaluationRunner)
            }
            
            Tab("Explore", systemImage: "sparkle.magnifyingglass") {
                NavigationStack {
                    ExploreView()
                        .navigationTitle("Explore")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.large)
                        #endif
                }
            }
        }
    }
    
    @ViewBuilder
    private func trainView(for type: EnvironmentType) -> some View {
        NavigationStack {
            switch type {
            case .frozenLake:
                FrozenLakeView(runner: frozenLakeRunner)
            case .blackjack:
                BlackjackView(runner: blackjackRunner)
            case .taxi:
                TaxiView(runner: taxiRunner)
            case .cliffWalking:
                CliffWalkingView(runner: cliffWalkingRunner)
            case .cartPole:
                CartPoleView(runner: cartPoleRunner)
            case .mountainCar:
                MountainCarView(runner: mountainCarRunner)
            case .mountainCarContinuous:
                MountainCarContinuousView(runner: mountainCarContinuousRunner)
            case .acrobot:
                AcrobotView(runner: acrobotRunner)
            case .pendulum:
                PendulumView(runner: pendulumRunner)
            case .lunarLander:
                LunarLanderView(runner: lunarLanderRunner)
            case .lunarLanderContinuous:
                LunarLanderContinuousView(runner: lunarLanderContinuousRunner)
            }
        }
    }
}

#Preview {
    MainView()
}


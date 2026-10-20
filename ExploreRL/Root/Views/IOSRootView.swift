import Gymnazo
import SwiftUI

#if os(iOS)
import UIKit

struct IOSRootView: View {
    @Bindable var trainViewModel: TrainViewModel
    @Binding var envSpecs: [EnvSpec]
    @Binding var selectedTab: AppTab
    @Binding var sessionToLoad: SavedSession?
    @Binding var sessionToEvaluate: SavedSession?
    @Binding var pendingImportURLs: [URL]
    let showExploreTab: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @SceneStorage("ipadTrainInspectorVisible") private var showIPadSettingsInspector = false
    @State private var trainNavigation = TrainNavigation()

    @ViewBuilder
    var body: some View {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            ipadLayout
        } else {
            tabLayout
        }
    }

    private var ipadLayout: some View {
        IPadWorkspaceView(
            trainViewModel: trainViewModel,
            selectedTab: $selectedTab,
            navigation: $trainNavigation,
            envSpecs: envSpecs,
            showExplore: showExploreTab
        ) {
            ipadDetail
        }
        .inspector(isPresented: ipadInspectorBinding) {
            if let id = trainNavigation.selectedEnvironmentID {
                TrainSettingsView(envID: id, vm: trainViewModel, showsDismissButton: false)
                    .id(id)
                    .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
            }
        }
    }

    @ViewBuilder
    private var ipadDetail: some View {
        switch selectedTab {
        case .home:
            homeView
        case .library:
            libraryView
        case .train:
            TrainView(
                viewModel: trainViewModel,
                envSpecs: $envSpecs,
                sessionToLoad: $sessionToLoad,
                navigation: $trainNavigation,
                showSettingsInspector: $showIPadSettingsInspector
            )
        case .evaluate:
            EvaluateView(
                sessionToLoad: $sessionToEvaluate,
                onGoToLibrary: { selectedTab = .library },
                usesWorkspaceNavigation: true
            )
        case .explore:
            ExploreView()
        case .settings:
            SettingsView()
        }
    }

    private var ipadInspectorBinding: Binding<Bool> {
        Binding(
            get: {
                showIPadSettingsInspector && selectedTab == .train
                    && trainNavigation.selectedEnvironmentID != nil
            },
            set: { showIPadSettingsInspector = $0 }
        )
    }

    private var tabLayout: some View {
        TabView(selection: $selectedTab) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                Tab("Home", systemImage: "house", value: AppTab.home) {
                    NavigationStack {
                        homeView
                    }
                }
            }

            Tab("Library", systemImage: "books.vertical", value: AppTab.library) {
                libraryView
            }

            Tab("Train", systemImage: "brain", value: AppTab.train) {
                TrainView(
                    viewModel: trainViewModel,
                    envSpecs: $envSpecs,
                    sessionToLoad: $sessionToLoad,
                    navigation: $trainNavigation
                )
            }

            Tab("Evaluate", systemImage: "play.circle", value: AppTab.evaluate) {
                makeEvaluateView {
                    selectedTab = .library
                }
            }

            if showExploreTab {
                Tab("Explore", systemImage: "graduationcap", value: AppTab.explore) {
                    ExploreView()
                }
            }

            Tab("Settings", systemImage: "gear", value: AppTab.settings) {
                SettingsView()
            }
        }
    }

    private var libraryView: some View {
        LibraryView(
            externalImportURLs: $pendingImportURLs,
            onLoad: loadSession,
            onEvaluate: evaluateSession
        )
    }

    private var homeView: some View {
        HomeView(
            envSpecs: envSpecs,
            showExplore: showExploreTab,
            onTrainEnvironment: { id in
                trainNavigation.selectedEnvironmentID = id
                selectedTab = .train
            },
            onOpenLibrary: { selectedTab = .library },
            onOpenEvaluate: { selectedTab = .evaluate },
            onOpenExplore: { selectedTab = .explore },
            onOpenSettings: { selectedTab = .settings },
            onLoadSession: loadSession,
            onEvaluateSession: evaluateSession
        )
    }

    private func loadSession(_ session: SavedSession) {
        sessionToLoad = session
        selectedTab = .train
    }

    private func evaluateSession(_ session: SavedSession) {
        sessionToEvaluate = session
        selectedTab = .evaluate
    }

    private func makeEvaluateView(onGoToLibrary: @escaping () -> Void) -> some View {
        EvaluateView(sessionToLoad: $sessionToEvaluate, onGoToLibrary: onGoToLibrary)
    }
}
#endif

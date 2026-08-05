import Gymnazo
import SwiftUI

struct ContentView: View {
    @State private var envSpecs: [EnvSpec] = []
    @State private var sessionToEvaluate: SavedSession?
    @State private var pendingImportURLs: [URL] = []
    @State private var showOnboarding = false

    #if os(macOS)
        @State private var trainViewModel = TrainViewModel()
        @SceneStorage("trainInspectorVisible") private var showTrainSettingsInspector = true
        @State private var selectedSidebarDestination: RootDestination = .home
        @SceneStorage("sidebarDestination") private var storedSidebarDestination = "home"
        @State private var trainLoadError: String?
        @State private var isLoadingTrainSession = false
        @State private var environmentSearchText = ""

        private func restoreSidebarDestination() {
            if let dest = RootDestination.fromStorageKey(storedSidebarDestination) {
                switch dest {
                case .library, .evaluate, .explore:
                    selectedSidebarDestination = .home
                    storedSidebarDestination = RootDestination.home.storageKey
                default:
                    selectedSidebarDestination = dest
                }
            }
        }
    #else
        @SceneStorage("selectedTab") private var selectedTab = "Train"
        @State private var sessionToLoad: SavedSession?
    #endif

    @AppStorage(AppPreferenceKeys.showExploreTab) private var showExploreTab = true
    @AppStorage(AppPreferenceKeys.hasSeenOnboarding) private var hasSeenOnboarding = false

    var body: some View {
        Group {
            #if os(macOS)
                macLayout
            #else
                iosTabLayout
            #endif
        }
        .onOpenURL { url in
            guard url.pathExtension.lowercased() == "xrlsession" else { return }
            pendingImportURLs.append(url)
            #if os(macOS)
                selectedSidebarDestination = .library
                storedSidebarDestination = selectedSidebarDestination.storageKey
            #else
                selectedTab = "Library"
            #endif
        }
        .task {
            envSpecs = await Gymnazo.registry().values.sorted { $0.id < $1.id }
        }
        .onAppear {
            #if os(macOS)
                restoreSidebarDestination()
            #endif
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: showExploreTab) { _, show in
            guard !show else { return }
            #if os(macOS)
                if selectedSidebarDestination == .explore {
                    selectedSidebarDestination = .home
                    storedSidebarDestination = selectedSidebarDestination.storageKey
                }
            #else
                if selectedTab == "Explore" {
                    selectedTab = "Train"
                }
            #endif
        }
        #if os(macOS)
            .alert(
                "Load Failed",
                isPresented: .init(
                    get: { trainLoadError != nil },
                    set: { if !$0 { trainLoadError = nil } }
                )
            ) {
                Button("OK") { trainLoadError = nil }
            } message: {
                Text(trainLoadError ?? "")
            }
        #endif
        #if os(iOS)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(pages: OnboardingItem.pages) {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
                .interactiveDismissDisabled()
            }
        #else
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(pages: OnboardingItem.pages) {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
                .frame(minWidth: 900, minHeight: 700)
            }
        #endif
    }

    // MARK: - Shared View Builders

    private func makeLibraryView(
        onLoad: @escaping (SavedSession) -> Void,
        onEvaluate: @escaping (SavedSession) -> Void
    ) -> some View {
        LibraryView(
            externalImportURLs: $pendingImportURLs,
            onLoad: onLoad,
            onEvaluate: onEvaluate
        )
    }

    private var exploreView: some View {
        ExploreView()
    }

    private func makeEvaluateView(onGoToLibrary: @escaping () -> Void) -> some View {
        EvaluateView(
            sessionToLoad: $sessionToEvaluate,
            onGoToLibrary: onGoToLibrary
        )
    }

    // MARK: - iOS Layout

    #if os(iOS)
        private var iosTabLayout: some View {
            TabView(selection: $selectedTab) {
                Tab("Library", systemImage: "books.vertical", value: "Library") {
                    makeLibraryView(
                        onLoad: { session in
                            sessionToLoad = session
                            selectedTab = "Train"
                        },
                        onEvaluate: { session in
                            sessionToEvaluate = session
                            selectedTab = "Evaluate"
                        }
                    )
                }

                Tab("Train", systemImage: "brain", value: "Train") {
                    TrainView(envSpecs: $envSpecs, sessionToLoad: $sessionToLoad)
                }

                Tab("Evaluate", systemImage: "play.circle", value: "Evaluate") {
                    makeEvaluateView {
                        selectedTab = "Library"
                    }
                }

                if showExploreTab {
                    Tab("Explore", systemImage: "graduationcap", value: "Explore") {
                        exploreView
                    }
                }

                Tab("Settings", systemImage: "gear", value: "Settings") {
                    SettingsView()
                }
            }
        }
    #endif

    // MARK: - macOS Layout

    #if os(macOS)
        private var macLayout: some View {
            NavigationSplitView {
                sidebarContent
            } detail: {
                detailContent
                    .overlay {
                        if isLoadingTrainSession {
                            ZStack {
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .ignoresSafeArea()
                                ProgressView("Loading session...")
                                    .padding(20)
                                    .background(
                                        .regularMaterial,
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                            }
                        }
                    }
            }
            .modify(if: selectedTrainEnvironmentID != nil) { content in
                content
                    .inspector(isPresented: $showTrainSettingsInspector) {
                        trainInspectorContent
                    }
            }
            .onChange(of: selectedTrainEnvironmentID) { oldValue, newValue in
                if newValue == nil {
                    showTrainSettingsInspector = false
                } else if oldValue == nil {
                    showTrainSettingsInspector = true
                }
            }
        }

        private var sidebarContent: some View {
            List(selection: sidebarBinding) {
                Section("App") {
                    ForEach(appSidebarItems, id: \.destination) { item in
                        Label(item.title, systemImage: item.systemImage)
                            .tag(item.destination)
                    }
                }

                ForEach(environmentSections, id: \.category) { section in
                    Section(section.category.rawValue) {
                        ForEach(section.items, id: \.id) { spec in
                            trainSidebarLabel(spec)
                                .tag(RootDestination.trainEnvironment(spec.id))
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ExploreRL")
            .navigationSplitViewColumnWidth(min: 230, ideal: 280, max: 360)
            .searchable(
                text: $environmentSearchText,
                placement: .sidebar,
                prompt: "Search environments"
            )
        }

        @ViewBuilder
        private var detailContent: some View {
            Group {
                switch selectedSidebarDestination {
                case .home:
                    MacHomeView(
                        envSpecs: envSpecs,
                        showExplore: showExploreTab,
                        onTrainEnvironment: selectTrainingEnvironment,
                        onOpenLibrary: openLibrary,
                        onOpenEvaluate: openEvaluate,
                        onOpenExplore: openExplore,
                        onOpenSettings: openSettings,
                        onLoadSession: handleLibraryLoad,
                        onEvaluateSession: handleLibraryEvaluate
                    )
                case .library:
                    makeLibraryView(
                        onLoad: handleLibraryLoad,
                        onEvaluate: handleLibraryEvaluate
                    )
                case .trainEnvironment(let envID):
                    TrainDetailView(
                        id: envID,
                        vm: trainViewModel,
                        showSettingsInspector: $showTrainSettingsInspector
                    )
                case .evaluate:
                    makeEvaluateView(onGoToLibrary: openLibrary)
                case .explore:
                    exploreView
                case .settings:
                    SettingsView()
                }
            }
            .toolbar {
                if selectedSidebarDestination != .home {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            goHome()
                        } label: {
                            Label("Home", systemImage: "house")
                        }
                    }
                }
            }
        }

        private var environmentSections: [(category: EnvCategory, items: [EnvSpec])] {
            EnvCategory.allCases.compactMap { category in
                let items = envSpecs.filter {
                    $0.category == category && $0.matchesSearch(environmentSearchText)
                }
                return items.isEmpty ? nil : (category, items)
            }
        }

        private var sidebarBinding: Binding<RootDestination?> {
            Binding(
                get: { selectedSidebarDestination },
                set: { newValue in
                    guard let newValue else { return }
                    selectedSidebarDestination = newValue
                    storedSidebarDestination = newValue.storageKey
                }
            )
        }

        private var appSidebarItems:
            [(title: String, systemImage: String, destination: RootDestination)]
        {
            [("Home", "house", .home)]
        }

        private func selectTrainingEnvironment(_ id: String) {
            selectedSidebarDestination = .trainEnvironment(id)
            storedSidebarDestination = selectedSidebarDestination.storageKey
        }

        private func openLibrary() {
            selectedSidebarDestination = .library
            storedSidebarDestination = selectedSidebarDestination.storageKey
        }

        private func openEvaluate() {
            selectedSidebarDestination = .evaluate
            storedSidebarDestination = selectedSidebarDestination.storageKey
        }

        private func openExplore() {
            guard showExploreTab else { return }
            selectedSidebarDestination = .explore
            storedSidebarDestination = selectedSidebarDestination.storageKey
        }

        private func openSettings() {
            selectedSidebarDestination = .settings
            storedSidebarDestination = selectedSidebarDestination.storageKey
        }

        private func goHome() {
            selectedSidebarDestination = .home
            storedSidebarDestination = selectedSidebarDestination.storageKey
        }

        private func trainSidebarLabel(_ spec: EnvSpec) -> some View {
            HStack(spacing: 8) {
                Text(spec.displayName ?? spec.name)
                    .lineLimit(1)
                Spacer()
                TrainingStatusIndicator(
                    status: trainViewModel.trainingState(for: spec.id).status
                )
            }
        }

        private var selectedTrainEnvironmentID: String? {
            if case .trainEnvironment(let envID) = selectedSidebarDestination {
                envID
            } else {
                nil
            }
        }

        @ViewBuilder
        private var trainInspectorContent: some View {
            if let envID = selectedTrainEnvironmentID {
                TrainSettingsView(
                    envID: envID,
                    vm: trainViewModel,
                    showsDismissButton: false
                )
                .id(envID)
                .inspectorColumnWidth(min: 320, ideal: 360, max: 440)
            } else {
                EmptyView()
            }
        }

        private func handleLibraryLoad(_ session: SavedSession) {
            selectedSidebarDestination = .trainEnvironment(session.environmentID)
            storedSidebarDestination = selectedSidebarDestination.storageKey
            isLoadingTrainSession = true
            Task { @MainActor in
                do {
                    try await trainViewModel.loadSession(session)
                } catch {
                    trainLoadError = error.localizedDescription
                }
                isLoadingTrainSession = false
            }
        }

        private func handleLibraryEvaluate(_ session: SavedSession) {
            sessionToEvaluate = session
            selectedSidebarDestination = .evaluate
            storedSidebarDestination = selectedSidebarDestination.storageKey
        }

        private enum RootDestination: Hashable {
            case home
            case library
            case trainEnvironment(String)
            case evaluate
            case explore
            case settings

            var storageKey: String {
                switch self {
                case .home: return "home"
                case .library: return "library"
                case .evaluate: return "evaluate"
                case .explore: return "explore"
                case .settings: return "settings"
                case .trainEnvironment(let id): return "train:\(id)"
                }
            }

            static func fromStorageKey(_ key: String) -> RootDestination? {
                switch key {
                case "home": return .home
                case "library": return .library
                case "evaluate": return .evaluate
                case "explore": return .explore
                case "settings": return .settings
                default:
                    if key.hasPrefix("train:") {
                        return .trainEnvironment(String(key.dropFirst(6)))
                    }
                    return nil
                }
            }
        }
    #endif
}

#Preview {
    ContentView()
}

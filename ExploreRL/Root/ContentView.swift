//
//  ContentView.swift
//  ExploreRL
//

import Gymnazo
import SwiftUI

struct ContentView: View {
    @State private var envSpecs: [EnvSpec] = []
    @State private var selectedTab = "Train"
    @State private var sessionToLoad: SavedSession?
    @State private var sessionToEvaluate: SavedSession?
    @State private var pendingImportURLs: [URL] = []
    @State private var showOnboarding = false

    @AppStorage(AppPreferenceKeys.showExploreTab) private var showExploreTab = true
    @AppStorage(AppPreferenceKeys.hasSeenOnboarding) private var hasSeenOnboarding = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Library", systemImage: "books.vertical", value: "Library") {
                LibraryView(
                    externalImportURLs: $pendingImportURLs,
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
                EvaluateView(sessionToLoad: $sessionToEvaluate, onGoToLibrary: {
                    selectedTab = "Library"
                })
            }

            if showExploreTab {
                Tab("Explore", systemImage: "graduationcap", value: "Explore") {
                    ExploreView()
                }
            }
            
            #if !os(macOS)
            Tab("Settings", systemImage: "gear", value: "Settings") {
                SettingsView()
            }
            #endif
        }
        .onOpenURL { url in
            guard url.pathExtension.lowercased() == "xrlsession" else { return }
            pendingImportURLs.append(url)
            selectedTab = "Library"
        }
        .task {
            envSpecs = await Gymnazo.registry().values.sorted {
                $0.id < $1.id
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: showExploreTab) { _, show in
            if !show && selectedTab == "Explore" {
                selectedTab = "Train"
            }
        }
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
}

#Preview {
    ContentView()
}

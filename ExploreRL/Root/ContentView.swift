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

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Library", systemImage: "books.vertical", value: "Library") {
                LibraryView(
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
                EvaluateView(sessionToLoad: $sessionToEvaluate)
            }

            Tab("Explore", systemImage: "graduationcap", value: "Explore") {
                ExploreView()
            }
            
            Tab("Settings", systemImage: "gear", value: "Settings") {
                SettingsView()
            }
        }
        .task {
            envSpecs = await Gymnazo.registry().values.sorted {
                $0.id < $1.id
            }
        }
    }
}

#Preview {
    ContentView()
}

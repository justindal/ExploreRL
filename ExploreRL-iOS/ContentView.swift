//
//  ContentView.swift

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .train
    private var trainingState = TrainingState.shared
    
    enum AppTab: String, CaseIterable {
        case train = "Train"
        case evaluate = "Evaluate"
        case library = "Library"
        
        var icon: String {
            switch self {
            case .train: return "graduationcap"
            case .evaluate: return "play.circle"
            case .library: return "books.vertical"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TrainTabView()
                .tabItem {
                    Label(AppTab.train.rawValue, systemImage: AppTab.train.icon)
                }
                .tag(AppTab.train)
            
            EvaluateTabView()
                .tabItem {
                    Label(AppTab.evaluate.rawValue, systemImage: AppTab.evaluate.icon)
                }
                .tag(AppTab.evaluate)
            
            LibraryTabView()
                .tabItem {
                    Label(AppTab.library.rawValue, systemImage: AppTab.library.icon)
                }
                .tag(AppTab.library)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if trainingState.isTraining && newValue != .train {
                selectedTab = oldValue
            }
        }
    }
}

#Preview {
    ContentView()
}

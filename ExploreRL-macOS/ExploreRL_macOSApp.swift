//
//  ExploreRL_macOSApp.swift
//  ExploreRL-macOS
//
//  Created by Justin Daludado on 2025-11-16.
//

import SwiftUI

@main
struct ExploreRL_macOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            LibrarySettingsView()
                .frame(minWidth: 450, minHeight: 300)
        }
    }
}

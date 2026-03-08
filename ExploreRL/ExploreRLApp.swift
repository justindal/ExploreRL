//
//  ExploreRLApp.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-02.
//

import SwiftUI
import MLX
import Gymnazo

#if os(macOS)
import AppKit
#endif

@main
struct ExploreRLApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 800)
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

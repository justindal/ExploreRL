//
//  ExploreRLApp.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-02.
//

import Gymnazo
import MLX
import SwiftUI

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
            .defaultSize(width: 1280, height: 820)
        #endif

        #if os(macOS)
            Settings {
                SettingsView()
            }
        #endif
    }
}

//
//  TrainDetailView.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-23.
//

#if os(macOS)
import AppKit
import Foundation

enum SessionSharePresenter {
    @MainActor
    static func present(url: URL) {
        guard
            let window = NSApp.keyWindow ?? NSApp.mainWindow,
            let contentView = window.contentView
        else {
            return
        }

        let picker = NSSharingServicePicker(items: [url])
        let anchor = NSRect(
            x: contentView.bounds.midX,
            y: contentView.bounds.midY,
            width: 1,
            height: 1
        )
        picker.show(relativeTo: anchor, of: contentView, preferredEdge: .minY)
    }
}
#endif

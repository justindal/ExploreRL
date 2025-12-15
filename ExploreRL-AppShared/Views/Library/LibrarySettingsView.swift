//
//  LibrarySettingsView.swift
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct LibrarySettingsView: View {
    @AppStorage("useiCloudSync") private var useiCloudSync = false
    @State private var confirmations = true
    @State private var showNotion = false
    @State private var showImportPicker = false
    @State private var importedAgents: [SavedAgent] = []
    @State private var showImportConfirmation = false
    @State private var isMigrating = false
    @State private var migrationError: String?
    @State private var showFolderPicker = false
    
    private var iCloudAvailable: Bool {
        AgentStorage.shared.iCloudAvailable
    }
    
    var body: some View {
        List {
            Section("General") {
                HStack(spacing: 10) {
                    Image(systemName: "icloud")
                    Toggle(isOn: $useiCloudSync) {
                        Text("iCloud sync")
                    }
                    .disabled(!iCloudAvailable || isMigrating)
                    .onChange(of: useiCloudSync) { _, newValue in
                        performMigration(toICloud: newValue)
                    }
                }
                .toggleStyle(.switch)
                .foregroundStyle(iCloudAvailable ? .primary : .secondary)
                
                if isMigrating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Migrating agents...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = migrationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.bubble")
                    Toggle(isOn: $confirmations) {
                        Text("Show confirmations")
                    }
                }
                .toggleStyle(.switch)
            }
            
            Section("Data") {
                NavigationLink {
                    AgentExportsView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Data export")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    openSavedAgentsFolder()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "folder")
                        Text("Open saved agents folder")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Support") {
                Button {
                    showNotion = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle")
                        Text("Feature & bug reports")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Settings")
        .sheet(isPresented: $showFolderPicker) {
            #if os(iOS)
            FolderPicker(url: AgentStorage.shared.agentsDirectoryURL)
            #endif
        }
        .sheet(isPresented: $showNotion) {
            SafariView(url: URL(string: "https://explorerl.notion.site/")!)
        }
    }
    
    private func settingsRow(icon: String, title: String, toggle: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Toggle(isOn: toggle) {
                Text(title)
            }
        }
        .toggleStyle(.switch)
    }
    
    private func openSavedAgentsFolder() {
        let url = AgentStorage.shared.agentsDirectoryURL
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #else
        UIApplication.shared.open(url)
        #endif
    }
}

#Preview {
    NavigationStack {
        LibrarySettingsView()
    }
}


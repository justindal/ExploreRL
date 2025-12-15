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
                        Image(systemName: "archivebox")
                        Text("Data export")
                    }
                }
                
                #if os(iOS)
                Button {
                    showFolderPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "folder")
                        Text("Saved agents folder")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                #else
                Button {
                    openInFinder()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "folder")
                        Text("Saved agents folder")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
                
                Button {
                    showImportPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import agents")
                        Spacer()
                        Image(systemName: "folder.badge.plus")
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
        .sheet(isPresented: $showNotion) {
            SafariView(url: URL(string: "https://explorerl.notion.site/")!)
        }
        .sheet(isPresented: $showImportPicker) {
            ImportPicker { agents in
                importedAgents = agents
                if !agents.isEmpty {
                    showImportConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showImportConfirmation) {
            ImportConfirmationView(agents: importedAgents) {
                importedAgents = []
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showFolderPicker) {
            FolderExportPicker(url: AgentStorage.shared.agentsDirectoryURL)
        }
        #endif
    }
    
    private func performMigration(toICloud: Bool) {
        isMigrating = true
        migrationError = nil
        
        Task {
            do {
                if toICloud {
                    try AgentStorage.shared.migrateToICloud()
                } else {
                    try AgentStorage.shared.migrateToLocal()
                }
                await MainActor.run {
                    isMigrating = false
                }
            } catch {
                await MainActor.run {
                    isMigrating = false
                    migrationError = "Migration failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    #if os(macOS)
    private func openInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([AgentStorage.shared.agentsDirectoryURL])
    }
    #endif
}

#if os(iOS)
struct FolderExportPicker: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            dismiss()
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            dismiss()
        }
    }
}
#endif

#Preview {
    NavigationStack {
        LibrarySettingsView()
    }
}

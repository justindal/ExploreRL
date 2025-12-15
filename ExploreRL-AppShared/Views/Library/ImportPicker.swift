//
//  ImportPicker.swift
//

import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ImportPicker: View {
    let onAgentsDiscovered: ([SavedAgent]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("Import Agents")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select a folder to import. You can select the SavedAgents folder directly, or any folder containing agent subfolders with metadata.json and weights files.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                if isLoading {
                    ProgressView("Scanning for agents...")
                } else {
                    Button {
                        pickFolder()
                    } label: {
                        Label("Choose Folder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func pickFolder() {
        #if os(iOS)
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.delegate = DocumentPickerCoordinator.shared
        DocumentPickerCoordinator.shared.onPick = { url in
            processSelectedFolder(url)
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            var topController = root
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(picker, animated: true)
        }
        #else
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing saved agents"
        
        if panel.runModal() == .OK, let url = panel.url {
            processSelectedFolder(url)
        }
        #endif
    }
    
    private func processSelectedFolder(_ url: URL) {
        isLoading = true
        errorMessage = nil
        
        let accessing = url.startAccessingSecurityScopedResource()
        
        Task {
            do {
                let agents = try await SavedAgentsImporter.discoverAgents(in: url)
                
                await MainActor.run {
                    isLoading = false
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    if agents.isEmpty {
                        errorMessage = "No valid agents found in the selected folder."
                    } else {
                        dismiss()
                        onAgentsDiscovered(agents)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                    errorMessage = "Error scanning folder: \(error.localizedDescription)"
                }
            }
        }
    }
}

#if os(iOS)
class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    static let shared = DocumentPickerCoordinator()
    var onPick: ((URL) -> Void)?
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        onPick?(url)
        onPick = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onPick = nil
    }
}
#endif

#Preview {
    ImportPicker { agents in
        print("Found \(agents.count) agents")
    }
}


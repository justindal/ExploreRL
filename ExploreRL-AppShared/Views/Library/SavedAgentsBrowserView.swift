//
//  SavedAgentsBrowserView.swift
//

import SwiftUI

struct SavedAgentsBrowserView: View {
    @State private var items: [FileItem] = []
    @State private var currentPath: URL = AgentStorage.shared.agentsDirectoryURL
    @State private var pathStack: [URL] = []
    @State private var itemToShare: URL?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: FileItem?
    
    var body: some View {
        List {
            if !pathStack.isEmpty {
                Button {
                    goBack()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Empty Folder", systemImage: "folder")
                } description: {
                    Text("No files or folders here.")
                }
            } else {
                ForEach(items) { item in
                    itemRow(item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                itemToShare = item.url
                                showShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                itemToShare = item.url
                                showShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle(currentPath.lastPathComponent)
        .onAppear {
            loadItems()
        }
        .alert("Delete Item?", isPresented: $showDeleteConfirmation, presenting: itemToDelete) { item in
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteItem(item)
            }
        } message: { item in
            Text("Are you sure you want to delete \"\(item.name)\"? This cannot be undone.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = itemToShare {
                ShareSheet(items: [url])
            }
        }
    }
    
    @ViewBuilder
    private func itemRow(_ item: FileItem) -> some View {
        if item.isDirectory {
            Button {
                navigateTo(item.url)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    Text(item.name)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } else {
            HStack(spacing: 10) {
                Image(systemName: iconForFile(item.name))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                    if let size = item.formattedSize {
                        Text(size)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
    
    private func iconForFile(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "json":
            return "doc.text"
        case "safetensors", "npy":
            return "cube"
        case "zip":
            return "archivebox"
        default:
            return "doc"
        }
    }
    
    private func loadItems() {
        let fm = FileManager.default
        do {
            let contents = try fm.contentsOfDirectory(at: currentPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey])
            items = contents.compactMap { url in
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return FileItem(url: url, isDirectory: isDir, size: Int64(size))
            }.sorted { a, b in
                if a.isDirectory != b.isDirectory {
                    return a.isDirectory
                }
                return a.name.localizedCompare(b.name) == .orderedAscending
            }
        } catch {
            items = []
        }
    }
    
    private func navigateTo(_ url: URL) {
        pathStack.append(currentPath)
        currentPath = url
        loadItems()
    }
    
    private func goBack() {
        guard let previous = pathStack.popLast() else { return }
        currentPath = previous
        loadItems()
    }
    
    private func deleteItem(_ item: FileItem) {
        try? FileManager.default.removeItem(at: item.url)
        itemToDelete = nil
        loadItems()
        AgentStorage.shared.loadAgentList()
    }
}

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
    let size: Int64
    
    var name: String {
        url.lastPathComponent
    }
    
    var formattedSize: String? {
        guard !isDirectory else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct ShareSheet: View {
    let items: [Any]
    
    var body: some View {
        #if os(iOS)
        ActivityViewController(items: items)
        #else
        VStack(spacing: 16) {
            Text("Share")
                .font(.headline)
            if let url = items.first as? URL {
                Text(url.lastPathComponent)
                    .foregroundStyle(.secondary)
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 300)
        #endif
    }
}

#if os(iOS)
struct ActivityViewController: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    NavigationStack {
        SavedAgentsBrowserView()
    }
}


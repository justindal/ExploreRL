//
//  AgentExportsView.swift
//

import SwiftUI

struct AgentExportsView: View {
    @State private var exports: [AgentExport] = []
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var exportToDelete: AgentExport?
    @State private var showDeleteConfirmation = false
    @State private var exportToShare: AgentExport?
    
    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Section {
                Button {
                    createExport()
                } label: {
                    HStack {
                        Image(systemName: isCreating ? "hourglass" : "plus.circle")
                        Text(isCreating ? "Creating export..." : "Create new export")
                        Spacer()
                    }
                }
                .disabled(isCreating)
            }
            
            Section("Previous Exports") {
                if exports.isEmpty {
                    ContentUnavailableView {
                        Label("No Exports", systemImage: "archivebox")
                    } description: {
                        Text("Create an export to back up your saved agents.")
                    }
                } else {
                    ForEach(exports) { item in
                        exportRow(item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    exportToDelete = item
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    exportToShare = item
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    exportToShare = item
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    exportToDelete = item
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
        .navigationTitle("Data Export")
        .onAppear(perform: loadExports)
        .refreshable {
            loadExports()
        }
        .alert("Delete Export?", isPresented: $showDeleteConfirmation, presenting: exportToDelete) { item in
            Button("Cancel", role: .cancel) {
                exportToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteExport(item)
            }
        } message: { item in
            Text("Are you sure you want to delete \"\(item.name)\"? This cannot be undone.")
        }
        .sheet(item: $exportToShare) { item in
            ShareSheet(items: [item.url])
        }
    }
    
    @ViewBuilder
    private func exportRow(_ item: AgentExport) -> some View {
        Button {
            exportToShare = item
        } label: {
            HStack {
                Image(systemName: "archivebox")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        Text(item.formattedDate)
                        Text("•")
                        Text(item.formattedSize)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func loadExports() {
        exports = SavedAgentsExporter.listExports()
    }
    
    private func createExport() {
        isCreating = true
        errorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let _ = try SavedAgentsExporter.createExport()
                DispatchQueue.main.async {
                    isCreating = false
                    loadExports()
                }
            } catch {
                DispatchQueue.main.async {
                    isCreating = false
                    errorMessage = "Failed to create export: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteExport(_ item: AgentExport) {
        do {
            try SavedAgentsExporter.deleteExport(item)
            loadExports()
        } catch {
            errorMessage = "Failed to delete export: \(error.localizedDescription)"
        }
        exportToDelete = nil
    }
}

#Preview {
    NavigationStack {
        AgentExportsView()
    }
}


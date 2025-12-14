import SwiftUI

struct AgentExportsView: View {
    @State private var exports: [AgentExport] = []
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            
            Section {
                Button {
                    createExport()
                } label: {
                    HStack {
                        Image(systemName: isCreating ? "hourglass" : "folder.badge.plus")
                        Text(isCreating ? "Creating export..." : "Create export")
                        Spacer()
                    }
                }
                .disabled(isCreating)
            }
            
            Section("Previous exports") {
                if exports.isEmpty {
                    Text("No exports yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(exports) { item in
                        ShareLink(item: item.url) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline)
                                    Text(item.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Data export")
        .onAppear(perform: loadExports)
        .refreshable {
            loadExports()
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
                    errorMessage = "Failed to create export."
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AgentExportsView()
    }
}


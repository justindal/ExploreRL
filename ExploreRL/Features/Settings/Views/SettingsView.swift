import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    @State private var viewModel = SettingsViewModel()
    @State private var showSystemCheck = false
    @State private var showDeleteAllConfirmation = false
    @State private var showImportPicker = false
    @State private var showFAQ = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("System Check") {
                        showSystemCheck = true
                    }
                } header: {
                    Text("Performance")
                } footer: {
                    Text("View device info and run performance benchmarks.")
                }

                librarySection

                Section {
                    Button("Frequently Asked Questions") {
                        showFAQ = true
                    }

                    Button("Contact the Developer") {
                        let subject = "ExploreRL Feedback"
                        if let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "mailto:justin@justindaludado.com?subject=\(encoded)") {
                            openURL(url)
                        }
                    }
                } header: {
                    Text("Help")
                } footer: {
                    Text("Have a question or found a bug? We'd love to hear from you.")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Gymnazo Version", value: "0.11.0")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .onAppear { viewModel.refreshSessionCount() }
        }
        .sheet(isPresented: $showSystemCheck) {
            SystemCheckSheet(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $showFAQ) {
            FAQSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Delete All Saved Agents?",
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                viewModel.deleteAllSavedAgents()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .alert(
            "Delete Failed",
            isPresented: Binding(
                get: { viewModel.deleteAllError != nil },
                set: { if !$0 { viewModel.deleteAllError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.deleteAllError ?? "")
        }
        .alert(
            "Saved Agents Deleted",
            isPresented: Binding(
                get: { viewModel.deletedSessionsCount != nil },
                set: { if !$0 { viewModel.deletedSessionsCount = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Deleted \(viewModel.deletedSessionsCount ?? 0) saved sessions.")
        }
        .alert(
            "Transfer Failed",
            isPresented: Binding(
                get: { viewModel.transferError != nil },
                set: { if !$0 { viewModel.transferError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.transferError ?? "")
        }
        .alert(
            "Import Complete",
            isPresented: Binding(
                get: { viewModel.lastImportedCount != nil },
                set: { if !$0 { viewModel.lastImportedCount = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Imported \(viewModel.lastImportedCount ?? 0) session(s).")
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [SessionStorage.archiveContentType],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.importSessions(from: urls)
            case .failure(let error):
                viewModel.transferError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private var librarySection: some View {
        Section {
            ShareLink(
                item: SessionExport(),
                preview: SharePreview("ExploreRL Sessions")
            ) {
                Label("Export All Sessions", systemImage: "square.and.arrow.up")
            }
            .disabled(!viewModel.hasSessions)

            Button("Import Sessions") {
                showImportPicker = true
            }

            #if os(macOS)
            Button("Show in Finder") {
                viewModel.openAppFiles()
            }
            #else
            Label {
                Text("Files → On My iPhone → ExploreRL")
            } icon: {
                Image(systemName: "folder")
            }
            .foregroundStyle(.secondary)
            #endif

            Button("Delete All Saved Agents", role: .destructive) {
                showDeleteAllConfirmation = true
            }
            .disabled(!viewModel.hasSessions)
        } header: {
            Text("Library")
        } footer: {
            Text("Manage your saved sessions and checkpoints.")
        }
    }
}

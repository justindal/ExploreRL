import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    @State private var viewModel = SettingsViewModel()
    @State private var showSystemCheck = false
    @State private var showDeleteAllConfirmation = false
    @State private var showImportPicker = false
    @State private var showFAQ = false

    @AppStorage("showExploreTab") private var showExploreTab = true

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Enable Explore Tab", isOn: $showExploreTab)
                    }
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Customize your app experience.")
                }

                Section {
                    Button {
                        showSystemCheck = true
                    } label: {
                        HStack {
                            Text("System Check")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Performance")
                } footer: {
                    Text("View device info and run performance benchmarks.")
                }

                librarySection

                Section {
                    Button {
                        showFAQ = true
                    } label: {
                        HStack {
                            Text("Frequently Asked Questions")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        let subject = "ExploreRL Feedback"
                        if let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "mailto:justin@justindaludado.com?subject=\(encoded)") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Text("Contact the Developer")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Help")
                } footer: {
                    Text("Have a question or found a bug? We'd love to hear from you.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    if let exploreRLInfoURL = viewModel.exploreRLInfoURL {
                        Link(destination: exploreRLInfoURL) {
                            HStack {
                                Text("Learn More about ExploreRL")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                        .foregroundStyle(.blue)
                    }
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
            FAQSheet(viewModel: viewModel)
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
                HStack {
                    Text("Export All Sessions")
                        .foregroundStyle(.blue)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasSessions)

            Button {
                showImportPicker = true
            } label: {
                HStack {
                    Text("Import Sessions")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                showDeleteAllConfirmation = true
            } label: {
                HStack {
                    Text("Delete All Saved Agents")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .disabled(!viewModel.hasSessions)
        } header: {
            Text("Library")
        } footer: {
            Text("Manage your saved sessions and checkpoints.")
        }
    }
}

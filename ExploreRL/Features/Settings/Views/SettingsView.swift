#if os(iOS)
import UIKit
#endif
import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    @State private var viewModel = SettingsViewModel()
    @State private var showSystemCheck = false
    @State private var showDeleteAllConfirmation = false
    @State private var showResetConfirmation = false
    @State private var showImportPicker = false
    @State private var showFAQ = false
    @State private var showAcknowledgements = false
    @State private var showExportShare = false

    @AppStorage("showExploreTab") private var showExploreTab = true
    @AppStorage(AppPreferenceKeys.allowMultiEnvTraining) private var allowMultiEnvTraining = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Explore Tab", isOn: $showExploreTab)
                    Toggle(
                        "Allow Multi-Environment Training",
                        isOn: $allowMultiEnvTraining
                    )
                } header: {
                    Text("Preferences")
                } footer: {
                    Text(
                        allowMultiEnvTraining
                            ? "Different environments can train concurrently."
                            : "Only one environment can train at a time."
                    )
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
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Help")
                } footer: {
                    Text("Have a question or found a bug? We'd love to hear from you.")
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset All Settings")
                    }
                    .confirmationDialog(
                        "Reset All Settings?",
                        isPresented: $showResetConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            showExploreTab = true
                            allowMultiEnvTraining = false
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will restore all preferences to their defaults.")
                    }
                } footer: {
                    Text("Restore all preferences to their default values.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Button {
                        showAcknowledgements = true
                    } label: {
                        HStack {
                            Text("Acknowledgements")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
        .sheet(isPresented: $showAcknowledgements) {
            AcknowledgementsSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
        .onChange(of: viewModel.exportURL) { _, url in
            guard url != nil else { return }
            #if os(macOS)
            SessionSharePresenter.present(url: url!)
            viewModel.clearExportURL()
            #else
            showExportShare = true
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $showExportShare, onDismiss: {
            viewModel.clearExportURL()
        }) {
            if let url = viewModel.exportURL {
                ActivitySheet(url: url)
            }
        }
        #endif
        .alert(
            "Export Failed",
            isPresented: Binding(
                get: { viewModel.exportError != nil },
                set: { if !$0 { viewModel.exportError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.exportError ?? "")
        }
    }

    @ViewBuilder
    private var librarySection: some View {
        Section {
            Button {
                Task { await viewModel.exportAllSessions() }
            } label: {
                HStack {
                    if viewModel.isExporting {
                        ProgressView()
                            .controlSize(.small)
                        Text("Exporting...")
                    } else {
                        Text("Export All Sessions")
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasSessions || viewModel.isExporting)

            Button {
                showImportPicker = true
            } label: {
                HStack {
                    Text("Import Sessions")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        } header: {
            Text("Library")
        } footer: {
            Text("Manage your saved sessions and checkpoints.")
        }
    }

}

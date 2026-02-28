import SwiftUI

struct FAQSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List(FAQItem.all) { item in
                DisclosureGroup(item.question) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if item.hasAppFilesAction {
                            #if os(macOS)
                            Button("Show in Finder") {
                                viewModel.openAppFiles()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            #else
                            Text("Files Location: On My iPhone → ExploreRL")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                            #endif
                        }
                    }
                    .padding(.vertical, 4)
                }
                .font(.headline)
            }
            .navigationTitle("FAQ")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #if os(macOS)
            .frame(minWidth: 400, idealWidth: 500, minHeight: 400)
            #endif
        }
    }
}

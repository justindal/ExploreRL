import SwiftUI

struct FAQSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(FAQItem.all) { item in
                DisclosureGroup(item.question) {
                    Text(item.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        }
    }
}

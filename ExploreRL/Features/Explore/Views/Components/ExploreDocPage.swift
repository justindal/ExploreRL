import SwiftUI

struct ExploreDocPage<Content: View>: View {
    let title: String
    let relatedItems: [ExploreItem]
    @ViewBuilder let content: Content

    init(title: String, relatedItems: [ExploreItem] = [], @ViewBuilder content: () -> Content) {
        self.title = title
        self.relatedItems = relatedItems
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                content

                if !relatedItems.isEmpty {
                    relatedTopicsSection
                }
            }
            .padding()
        }
    }

    private var relatedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.top, 8)

            Text("Related Topics")
                .font(.headline)

            ForEach(relatedItems) { item in
                NavigationLink(value: item) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

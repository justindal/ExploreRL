import SwiftUI

struct SettingsSection<Content: View, Footer: View>: View {
    private let title: String?
    private let content: Content
    private let footer: Footer
    @Environment(\.isInspectorStyle) private var isInspectorStyle

    init(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) where Footer == EmptyView {
        self.title = title
        self.content = content()
        footer = EmptyView()
    }

    init(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        if isInspectorStyle {
            VStack(alignment: .leading, spacing: 8) {
                if let title {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                VStack(alignment: .leading, spacing: 10) {
                    content
                }

                if Footer.self != EmptyView.self {
                    footer
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 5)
        } else {
            Section {
                content
            } header: {
                if let title {
                    Text(title)
                }
            } footer: {
                footer
            }
        }
    }
}

#if os(macOS)
    import SwiftUI

    struct MacHomeActionCard: View {
        let title: String
        let message: String
        let systemImage: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(AppLayout.panelPadding)
                .background(
                    .thinMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens this area in ExploreRL")
        }
    }
#endif

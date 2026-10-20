import SwiftUI

struct HomeActionCard: View {
    let title: String
    let message: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .padding(AppLayout.panelPadding)
            .background(
                .thinMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
            )
        }
        .buttonStyle(.plain)
        .help(message)
        .accessibilityHint(message)
    }
}

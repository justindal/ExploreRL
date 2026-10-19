#if os(macOS)
    import Gymnazo
    import SwiftUI

    struct MacHomeEnvironmentCard: View {
        let spec: EnvSpec
        let action: () -> Void

        private var title: String {
            spec.displayName ?? spec.name
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(spec.category?.rawValue ?? "Environment")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }

                    Text(spec.description ?? "Configure this environment and train an agent.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
                .padding(AppLayout.panelPadding)
                .background(
                    .regularMaterial, in: RoundedRectangle(cornerRadius: AppLayout.panelRadius)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Train \(title)")
            .accessibilityHint("Opens training for this environment")
        }
    }
#endif

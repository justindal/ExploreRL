import SwiftUI

struct FixedSizeEnvWrapper<Content: View>: View {
    let baseSize: CGSize
    @ViewBuilder let content: Content

    var body: some View {
        Color.clear
            .aspectRatio(baseSize.width / baseSize.height, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let scale = min(proxy.size.width / baseSize.width, 1)
                    content
                        .frame(width: baseSize.width, height: baseSize.height)
                        .scaleEffect(scale, anchor: .topLeading)
                }
            }
            .frame(maxWidth: min(baseSize.width, 480 * baseSize.width / baseSize.height))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

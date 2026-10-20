import Gymnazo
import SwiftUI

struct MetroRunnerPreview: View {
    let snapshot: MetroRunnerSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.compactSpacing) {
            if dynamicTypeSize.isAccessibilitySize {
                MetroRunnerHUD(snapshot: snapshot)
            }
            FixedSizeEnvWrapper(baseSize: CGSize(width: 720, height: 500)) {
                MetroRunnerView(snapshot: snapshot)
            }
            .overlay(alignment: .topLeading) {
                if !dynamicTypeSize.isAccessibilitySize {
                    MetroRunnerHUD(snapshot: snapshot)
                }
            }
        }
    }
}

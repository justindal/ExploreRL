import Gymnazo
import SwiftUI

struct TrainingPhaseView: View {
    let phase: TrainingPhase

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .accessibilityHidden(true)
            Text(title)
                .font(.caption.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .help(detail)
        .accessibilityElement(children: .combine)
        .accessibilityHint(detail)
    }

    private var title: String {
        switch phase {
        case .preparing: "Preparing training"
        case .compiling: "Compiling training kernels"
        case .updating: "Updating the policy"
        case .collecting: "Collecting experience"
        }
    }

    private var detail: String {
        switch phase {
        case .preparing: "Loading the environment and preparing the model."
        case .compiling: "MLX is preparing and compiling training kernels. Steps resume after this update."
        case .updating: "Learning from the collected experience."
        case .collecting: ""
        }
    }
}

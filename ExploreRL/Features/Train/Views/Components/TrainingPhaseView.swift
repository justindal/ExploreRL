import Gymnazo
import SwiftUI

struct TrainingPhaseView: View {
    let phase: TrainingPhase

    var body: some View {
        if phase != .collecting {
            HStack(alignment: .top, spacing: 12) {
                ProgressView().controlSize(.small)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.medium))
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var title: String {
        switch phase {
        case .preparing: "Preparing training"
        case .compiling: "Preparing the first update"
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

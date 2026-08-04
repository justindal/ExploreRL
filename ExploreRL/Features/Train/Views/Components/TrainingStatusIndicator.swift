import SwiftUI

struct TrainingStatusIndicator: View {
    let status: TrainingStatus

    var body: some View {
        switch status {
        case .idle:
            EmptyView()
        case .training:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Training in progress")
        case .paused:
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(.orange)
                .accessibilityLabel("Training paused")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Training completed")
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .accessibilityLabel("Training failed")
        }
    }
}

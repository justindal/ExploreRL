import SwiftUI

struct TrainingProgressView: View {
    let id: String
    @Bindable var vm: TrainViewModel
    let trainingConfig: TrainingConfig
    let trainingState: TrainingState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var progress: Double {
        trainingState.progress(totalTimesteps: trainingConfig.totalTimesteps)
    }

    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(trainingState.episodeCount) episodes completed")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout())
            layout {
                Text("\(trainingState.currentTimestep) / \(trainingConfig.totalTimesteps) steps")
                    .font(.caption)
                    .monospacedDigit()
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                Text(String(format: "%.1f%%", progress * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
            timingRow
        }
    }

    private var timingRow: some View {
        let elapsed = vm.activeTrainingElapsed(for: id)
        let stepsPerMinute = stepsPerMin(timesteps: vm.timedTrainingSteps(for: id), elapsed: elapsed)
        let eta = etaSeconds(
            stepsPerMinute: stepsPerMinute, currentTimestep: trainingState.currentTimestep,
            totalTimesteps: trainingConfig.totalTimesteps)

        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())
        return layout {
            Text("Elapsed \(formatTime(elapsed))")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            if !dynamicTypeSize.isAccessibilitySize { Spacer() }
            Text("\(Int(stepsPerMinute.rounded())) steps/min")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            if !dynamicTypeSize.isAccessibilitySize { Spacer() }
            Text(eta.map { "ETA \(formatTime($0))" } ?? "ETA —")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.caption)
    }

}

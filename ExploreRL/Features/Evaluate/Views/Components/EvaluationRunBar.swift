import SwiftUI

struct EvaluationRunBar: View {
    let state: EvaluationState
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Episode \(min(state.currentEpisode + 1, state.totalEpisodes)) / \(state.totalEpisodes)")
                Spacer()
                Text(state.progress, format: .percent.precision(.fractionLength(0)))
            }
            .font(.caption.monospacedDigit())
            ProgressView(value: state.progress)
            Button(action: onStop) {
                Label("Stop Evaluation", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .modify { button in
                if #available(iOS 26.0, macOS 26.0, *) {
                    button
                        .buttonStyle(.glass(.regular.tint(.red).interactive()))
                        #if os(macOS)
                            .tint(.red)
                        #endif
                } else {
                    button
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
            }
            .controlSize(.large)
        }
        .padding(.horizontal, AppLayout.spacing)
        .padding(.vertical, AppLayout.compactSpacing)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}

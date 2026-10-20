import SwiftUI

struct TrainingEvaluationSheet: View {
    let id: String
    @Bindable var train: TrainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var flow = TrainingEvaluationViewModel()
    @State private var retry = 0

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = flow.snapshot, flow.isConfirmed {
                    EvaluateDetailView(
                        session: snapshot.session, vm: flow.evaluation, showsCloseButton: false,
                        checkpointDirectory: snapshot.checkpointDirectory, startsOnLoad: true
                    )
                } else if let snapshot = flow.snapshot {
                    confirmation(snapshot)
                } else if let errorMessage = flow.errorMessage {
                    ContentUnavailableView {
                        Label("Could Not Prepare Evaluation", systemImage: "exclamationmark.triangle")
                    } description: { Text(errorMessage) } actions: {
                        Button("Retry") { retry += 1 }
                    }
                } else {
                    ProgressView("Creating a temporary checkpoint…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(flow.isConfirmed ? "Evaluate Current Run" : "Evaluate This Run?")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(flow.isConfirmed ? "Done" : "Cancel") { dismiss() }
                        .disabled(flow.isSaving)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 660, idealWidth: 900, minHeight: 500, idealHeight: 720)
        #endif
        .interactiveDismissDisabled(flow.isSaving)
        .task(id: retry) { await flow.prepare(using: train, id: id) }
        .onDisappear { Task { await flow.close() } }
    }

    private func confirmation(_ snapshot: TrainingSnapshot) -> some View {
        @Bindable var evaluation = flow.evaluation
        return Form {
            Section {
                LabeledContent("Steps Trained", value: snapshot.session.trainingState.currentTimestep.formatted())
                Stepper("Episodes: \(evaluation.state.totalEpisodes)", value: $evaluation.state.totalEpisodes, in: 1...100)
                Toggle("Render Evaluation", isOn: $evaluation.state.renderEnabled)
            } footer: {
                Text("A temporary checkpoint is ready. Evaluation uses a separate copy of this agent and leaves training progress intact.")
            }
            Section {
                Toggle("Save to Library", isOn: $flow.saveToLibrary)
                if flow.saveToLibrary { TextField("Session Name", text: $flow.name) }
            } footer: {
                Text("The temporary checkpoint is removed when you close evaluation. Save it to keep a Library copy.")
            }
            if let errorMessage = flow.errorMessage { Text(errorMessage).foregroundStyle(.red) }
            Section {
                Button(flow.isSaving ? "Saving…" : "Evaluate") {
                    Task { await flow.confirm() }
                }
                .disabled(flow.isSaving || (flow.saveToLibrary && flow.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
    }
}

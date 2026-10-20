import SwiftUI

struct ContinueTrainingSheet: View {
    let id: String
    @Bindable var vm: TrainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var additionalSteps = 100_000
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Steps Trained", value: vm.trainingState(for: id).currentTimestep.formatted())
                    TextField("Additional Steps", value: $additionalSteps, format: .number)
                    if additionalSteps > 0, additionalSteps <= 1_000_000_000 - vm.trainingState(for: id).currentTimestep {
                        LabeledContent("New Step Target", value: (vm.trainingState(for: id).currentTimestep + additionalSteps).formatted())
                    }
                } footer: {
                    Text("Continue from the current learned weights and training history. Your existing Library sessions are preserved.")
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Continue Training")
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 420, minHeight: 280)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        do {
                            try vm.extendTraining(for: id, additionalTimesteps: additionalSteps)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .disabled(additionalSteps <= 0 || additionalSteps > 1_000_000_000 - vm.trainingState(for: id).currentTimestep)
                }
            }
            .onAppear {
                additionalSteps = EnvironmentDefaults.totalTimestepsDefault(for: id, algorithm: vm.trainingConfig(for: id).algorithm)
            }
        }
    }
}

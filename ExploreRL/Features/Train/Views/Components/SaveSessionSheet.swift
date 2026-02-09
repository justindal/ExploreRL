//
//  SaveSessionSheet.swift
//  ExploreRL
//

import SwiftUI

struct SaveSessionSheet: View {
    let environmentID: String
    let algorithmType: AlgorithmType
    let onSave: (String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Session Name", text: $name)
                        .textFieldStyle(.plain)
                }

                Section {
                    LabeledContent("Environment", value: environmentID)
                    LabeledContent("Algorithm", value: algorithmType.rawValue)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Save Session")
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 380, idealWidth: 440, minHeight: 260)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, h:mm a"
                name = "\(environmentID) - \(algorithmType.rawValue) - \(formatter.string(from: Date()))"
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            do {
                try await onSave(trimmed)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

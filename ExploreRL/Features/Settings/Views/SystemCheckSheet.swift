import SwiftUI

struct SystemCheckSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                readinessSection
                deviceSection
                memorySection
                powerSection
            }
            .navigationTitle("System Check")
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 460, idealWidth: 560, minHeight: 520)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .task {
                viewModel.loadDeviceInfo()
            }
        }
    }

    private var readinessSection: some View {
        Section {
            ForEach(viewModel.readinessChecks) { check in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(check.title, systemImage: iconName(for: check.level))
                            .foregroundStyle(color(for: check.level))
                        Spacer()
                        Text(check.value)
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(check.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Readiness")
        } footer: {
            Text("Use these checks to understand current performance conditions.")
        }
    }

    private var deviceSection: some View {
        Section("Device") {
            LabeledContent("Model", value: viewModel.deviceInfo.deviceModel)
            LabeledContent("GPU", value: viewModel.deviceInfo.gpuName)
            LabeledContent("CPU Cores", value: "\(viewModel.deviceInfo.cpuCores)")
            LabeledContent("OS", value: viewModel.deviceInfo.osVersion)
        }
    }

    private var memorySection: some View {
        Section("Memory") {
            LabeledContent("Unified Memory", value: viewModel.deviceInfo.physicalMemoryText)
            LabeledContent("Max Working Set", value: viewModel.deviceInfo.recommendedMaxWorkingSetText)
            LabeledContent("Current Allocated", value: viewModel.deviceInfo.currentAllocatedText)
            LabeledContent("Working Set Use", value: viewModel.deviceInfo.gpuWorkingSetUtilizationText)
        }
    }

    private var powerSection: some View {
        Section("Power") {
            LabeledContent("Thermal State", value: viewModel.deviceInfo.thermalState)
            LabeledContent("Low Power Mode", value: viewModel.deviceInfo.lowPowerMode ? "On" : "Off")
        }
    }

    private func color(for level: ReadinessLevel) -> Color {
        switch level {
        case .good:
            return .green
        case .attention:
            return .orange
        case .warning:
            return .red
        }
    }

    private func iconName(for level: ReadinessLevel) -> String {
        switch level {
        case .good:
            return "checkmark.circle.fill"
        case .attention:
            return "exclamationmark.circle.fill"
        case .warning:
            return "xmark.circle.fill"
        }
    }
}

import SwiftUI

struct SystemCheckSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var computeRequest = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                readinessSection
                computeSection
                deviceSection
                memorySection
                powerSection
            }
            .labeledContentStyle(AdaptiveLabeledContentStyle())
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
                while !Task.isCancelled {
                    if scenePhase == .active { viewModel.loadDeviceInfo() }
                    do { try await Task.sleep(for: .seconds(2)) } catch { return }
                }
            }
            .task(id: "\(computeRequest)-\(scenePhase == .active)") {
                guard computeRequest > 0, scenePhase == .active else { return }
                await viewModel.verifyCompute()
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
            Text("Current power, temperature and device availability. These conditions do not predict training speed.")
            if let sampledAt = viewModel.deviceInfo.sampledAt {
                Text("Updated \(sampledAt.formatted(date: .omitted, time: .standard))")
                    .monospacedDigit()
            }
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

    private var computeSection: some View {
        Section {
            if viewModel.isCheckingCompute {
                ProgressView("Checking MLX GPU computation…")
            } else {
                Button("Run Compute Check", systemImage: "checkmark.circle") { computeRequest += 1 }
                    .disabled(scenePhase != .active)
            }
            if let result = viewModel.computeResult { Text(result).font(.footnote) }
        } header: { Text("Compute Check") } footer: {
            Text("Verifies a small matrix calculation on the GPU. This is a correctness check, not a speed benchmark.")
        }
    }

    private var memorySection: some View {
        Section {
            LabeledContent("Physical Memory", value: viewModel.deviceInfo.physicalMemoryText)
            LabeledContent("Recommended Metal Working Set", value: viewModel.deviceInfo.recommendedMaxWorkingSetText)
            LabeledContent("App Memory Footprint", value: viewModel.deviceInfo.appFootprintBytes.map {
                Int64($0).formatted(.byteCount(style: .memory))
            } ?? "Unavailable")
            LabeledContent("MLX Active", value: viewModel.deviceInfo.memoryText(viewModel.deviceInfo.mlxActiveBytes))
            LabeledContent("MLX Cache", value: viewModel.deviceInfo.memoryText(viewModel.deviceInfo.mlxCacheBytes))
            LabeledContent("MLX Peak Active", value: viewModel.deviceInfo.memoryText(viewModel.deviceInfo.mlxPeakBytes))
        } header: { Text("App Memory") } footer: {
            Text("Refreshes every two seconds while this window is active. MLX active and cache are app allocations; peak is since launch. These are not system GPU utilization. The recommended working set is not the iOS app memory limit.")
        }
    }

    private var powerSection: some View {
        Section("Power") {
            LabeledContent("Thermal State", value: viewModel.deviceInfo.thermalState)
            LabeledContent(
                "Low Power Mode", value: viewModel.deviceInfo.lowPowerMode ? "On" : "Off")
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

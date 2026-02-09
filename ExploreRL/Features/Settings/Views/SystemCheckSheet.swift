import SwiftUI

struct SystemCheckSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                deviceSection
                memorySection
                powerSection
                benchmarkSection
            }
            .navigationTitle("System Check")
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 420, idealWidth: 520, minHeight: 520)
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
    
    private var deviceSection: some View {
        Section("Device") {
            LabeledContent("GPU", value: viewModel.deviceInfo.gpuName)
            LabeledContent("CPU Cores", value: "\(viewModel.deviceInfo.cpuCores)")
        }
    }
    
    private var memorySection: some View {
        Section("Memory") {
            LabeledContent("Max Working Set", value: viewModel.deviceInfo.recommendedMaxWorkingSetSize)
            LabeledContent("Current Allocated", value: viewModel.deviceInfo.currentAllocatedSize)
        }
    }
    
    private var powerSection: some View {
        Section("Power") {
            LabeledContent("Thermal State", value: viewModel.deviceInfo.thermalState)
            LabeledContent("Low Power Mode", value: viewModel.deviceInfo.lowPowerMode ? "On" : "Off")
        }
    }
    
    private var benchmarkSection: some View {
        Section {
            Button {
                Task { await viewModel.runBenchmarks() }
            } label: {
                HStack {
                    Text(viewModel.isRunningBenchmarks ? "Running…" : "Run Benchmarks")
                    Spacer()
                    if viewModel.isRunningBenchmarks {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isRunningBenchmarks)
            
            ForEach(viewModel.benchmarkResults) { result in
                BenchmarkRow(result: result)
            }
        } header: {
            Text("Benchmarks")
        } footer: {
            Text("Compares CPU vs GPU for common RL operations.")
        }
    }
}

private struct BenchmarkRow: View {
    let result: BenchmarkResult
    
    private var cpuFaster: Bool { result.cpuTimeMs < result.gpuTimeMs }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.name)
                .font(.subheadline)
            HStack(spacing: 16) {
                Text("CPU: \(String(format: "%.1f ms", result.cpuTimeMs))")
                    .font(.caption)
                    .fontWeight(cpuFaster ? .semibold : .regular)
                    .foregroundStyle(cpuFaster ? .primary : .secondary)
                Text("GPU: \(String(format: "%.1f ms", result.gpuTimeMs))")
                    .font(.caption)
                    .fontWeight(cpuFaster ? .regular : .semibold)
                    .foregroundStyle(cpuFaster ? .secondary : .primary)
                Spacer()
                Text(String(format: "%.1fx", result.speedup))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(result.speedup > 1 ? .green : .orange)
            }
        }
        .padding(.vertical, 2)
    }
}

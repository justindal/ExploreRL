import Foundation
import Metal
import MLX

#if os(macOS)
import AppKit
#endif

struct DeviceInfo {
    var gpuName: String = "N/A"
    var cpuCores: Int = 0
    var recommendedMaxWorkingSetSize: String = "N/A"
    var currentAllocatedSize: String = "N/A"
    var thermalState: String = "N/A"
    var lowPowerMode: Bool = false
}

struct BenchmarkResult: Identifiable {
    let id = UUID()
    let name: String
    let cpuTimeMs: Double
    let gpuTimeMs: Double
    
    var speedup: Double {
        guard gpuTimeMs > 0 else { return 0 }
        return cpuTimeMs / gpuTimeMs
    }
}

@MainActor
@Observable
final class SettingsViewModel {
    var isSystemCheckPresented = false

    var deleteAllError: String?
    var deletedSessionsCount: Int?
    var transferError: String?
    var lastImportedCount: Int?
    var exportError: String?
    private(set) var isExporting = false
    private(set) var exportURL: URL?
    private(set) var sessionCount = 0
    
    private(set) var deviceInfo = DeviceInfo()
    private(set) var isLoadingDevice = false
    
    private(set) var benchmarkResults: [BenchmarkResult] = []
    private(set) var isRunningBenchmarks = false
    let exploreRLInfoURL = URL(string: "https://www.justindaludado.com/explorerl")

    private let storage = SessionStorage.shared

    var hasSessions: Bool { sessionCount > 0 }

    func refreshSessionCount() {
        sessionCount = storage.listSessions().count
    }

    func deleteAllSavedAgents() {
        do {
            let count = storage.listSessions().count
            try storage.deleteAll()
            storage.invalidateExportCache()
            deleteAllError = nil
            deletedSessionsCount = count
            sessionCount = 0
        } catch {
            deletedSessionsCount = nil
            deleteAllError = error.localizedDescription
        }
    }

    func importSessions(from urls: [URL]) {
        do {
            var imported = 0
            for url in urls {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                imported += try storage.importSessions(from: url)
            }
            storage.invalidateExportCache()
            transferError = nil
            lastImportedCount = imported
            refreshSessionCount()
        } catch {
            lastImportedCount = nil
            transferError = error.localizedDescription
        }
    }

    func openAppFiles() {
        #if os(macOS)
        let url = storage.sessionsDirectory
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
        #endif
    }

    func exportAllSessions() async {
        guard !isExporting else { return }
        isExporting = true
        exportURL = nil
        exportError = nil
        do {
            let url = try await Task.detached {
                try await SessionStorage.shared.exportAllSessions()
            }.value
            exportURL = url
        } catch {
            exportError = error.localizedDescription
        }
        isExporting = false
    }

    func clearExportURL() {
        exportURL = nil
    }

    func loadDeviceInfo() {
        guard !isLoadingDevice else { return }
        isLoadingDevice = true
        defer { isLoadingDevice = false }
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            deviceInfo.gpuName = metalDevice.name
            deviceInfo.recommendedMaxWorkingSetSize = Int64(metalDevice.recommendedMaxWorkingSetSize)
                .formatted(.byteCount(style: .file))
            deviceInfo.currentAllocatedSize = Int64(metalDevice.currentAllocatedSize)
                .formatted(.byteCount(style: .file))
        }
        
        deviceInfo.cpuCores = ProcessInfo.processInfo.activeProcessorCount
        deviceInfo.lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: deviceInfo.thermalState = "Nominal"
        case .fair: deviceInfo.thermalState = "Fair"
        case .serious: deviceInfo.thermalState = "Serious"
        case .critical: deviceInfo.thermalState = "Critical"
        @unknown default: deviceInfo.thermalState = "Unknown"
        }
    }

    func runBenchmarks() async {
        guard !isRunningBenchmarks else { return }
        isRunningBenchmarks = true
        benchmarkResults = []
        
        let iterations = 10
        let benchmarks: [(String, (StreamOrDevice) -> Void)] = [
            ("Matrix Multiply", benchmarkMatmul),
            ("Batch Forward", benchmarkBatchForward),
            ("Softmax", benchmarkSoftmax),
            ("ReLU", benchmarkReLU),
            ("Argmax", benchmarkArgmax)
        ]
        
        for (name, benchmark) in benchmarks {
            var cpuTimes: [Double] = []
            var gpuTimes: [Double] = []
            
            for _ in 0..<iterations {
                cpuTimes.append(measureTime { benchmark(.cpu) })
                gpuTimes.append(measureTime { benchmark(.gpu) })
            }
            
            let avgCpu = cpuTimes.reduce(0, +) / Double(iterations)
            let avgGpu = gpuTimes.reduce(0, +) / Double(iterations)
            
            benchmarkResults.append(BenchmarkResult(
                name: name,
                cpuTimeMs: avgCpu * 1000,
                gpuTimeMs: avgGpu * 1000
            ))
        }
        
        isRunningBenchmarks = false
    }
    
    private func measureTime(_ operation: () -> Void) -> Double {
        let start = CFAbsoluteTimeGetCurrent()
        operation()
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    private func benchmarkMatmul(device: StreamOrDevice) {
        let a = MLX.uniform(0.1 ..< 1, [1024], stream: device)
        let b = MLX.uniform(0.1 ..< 1, [1024], stream: device)
        let c = MLX.matmul(a, b, stream: device)
        eval(c)
    }
    
    private func benchmarkBatchForward(device: StreamOrDevice) {
        let x = MLX.uniform(0.1 ..< 1, [256, 128], stream: device)
        let w = MLX.uniform(0.1 ..< 1, [128, 256], stream: device)
        let b = MLX.uniform(0.1 ..< 1, [256], stream: device)
        let y = MLX.matmul(x, w, stream: device) + b
        eval(y)
    }
    
    private func benchmarkSoftmax(device: StreamOrDevice) {
        let logits = MLX.uniform(0.1 ..< 1, [256, 64], stream: device)
        let probs = softmax(logits, axis: -1, stream: device)
        eval(probs)
    }
    
    private func benchmarkReLU(device: StreamOrDevice) {
        let x = MLX.uniform(-1 ..< 1, [256, 512], stream: device)
        let y = maximum(x, MLXArray(0), stream: device)
        eval(y)
    }
    
    private func benchmarkArgmax(device: StreamOrDevice) {
        let qValues = MLX.uniform(0.1 ..< 1, [256, 64], stream: device)
        let actions = argMax(qValues, axis: -1, stream: device)
        eval(actions)
    }
}

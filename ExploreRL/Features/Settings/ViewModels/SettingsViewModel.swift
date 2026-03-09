import Foundation
import Metal

#if canImport(Darwin)
import Darwin
#endif

#if os(macOS)
import AppKit
#endif

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
    private(set) var readinessChecks: [ReadinessCheck] = []
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

        var info = DeviceInfo()

        if let metalDevice = MTLCreateSystemDefaultDevice() {
            info.gpuName = metalDevice.name
            info.recommendedMaxWorkingSetBytes = UInt64(metalDevice.recommendedMaxWorkingSetSize)
            info.currentAllocatedBytes = UInt64(metalDevice.currentAllocatedSize)
        }

        info.cpuCores = ProcessInfo.processInfo.activeProcessorCount
        info.physicalMemoryBytes = ProcessInfo.processInfo.physicalMemory
        info.lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        info.osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        info.deviceModel = machineIdentifier()

        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            info.thermalState = "Nominal"
        case .fair:
            info.thermalState = "Fair"
        case .serious:
            info.thermalState = "Serious"
        case .critical:
            info.thermalState = "Critical"
        @unknown default:
            info.thermalState = "Unknown"
        }

        deviceInfo = info
        refreshReadinessChecks()
    }

    private func refreshReadinessChecks() {
        var checks: [ReadinessCheck] = []

        checks.append(
            ReadinessCheck(
                title: "Low Power Mode",
                value: deviceInfo.lowPowerMode ? "On" : "Off",
                detail: deviceInfo.lowPowerMode
                    ? "Disable Low Power Mode for stable GPU measurements."
                    : "Power settings are suitable for benchmark consistency.",
                level: deviceInfo.lowPowerMode ? .attention : .good
            )
        )

        let thermalLevel: ReadinessLevel
        switch deviceInfo.thermalState {
        case "Nominal":
            thermalLevel = .good
        case "Fair":
            thermalLevel = .attention
        case "Serious", "Critical":
            thermalLevel = .warning
        default:
            thermalLevel = .attention
        }

        checks.append(
            ReadinessCheck(
                title: "Thermal State",
                value: deviceInfo.thermalState,
                detail: "Lower thermal load keeps CPU and GPU results more repeatable.",
                level: thermalLevel
            )
        )

        if let utilization = deviceInfo.gpuWorkingSetUtilization {
            let level: ReadinessLevel
            switch utilization {
            case ..<0.5:
                level = .good
            case ..<0.8:
                level = .attention
            default:
                level = .warning
            }

            checks.append(
                ReadinessCheck(
                    title: "GPU Working Set",
                    value: deviceInfo.gpuWorkingSetUtilizationText,
                    detail: "Lower GPU memory pressure usually yields steadier timings.",
                    level: level
                )
            )
        }

        readinessChecks = checks
    }

    private func machineIdentifier() -> String {
        #if os(macOS)
        return sysctlString("hw.model")
            ?? sysctlString("machdep.cpu.brand_string")
            ?? "Unknown"
        #else
        return sysctlString("hw.machine") ?? "Unknown"
        #endif
    }

    private func sysctlString(_ key: String) -> String? {
        var size: size_t = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }
        var value = [CChar](repeating: 0, count: Int(size))
        guard sysctlbyname(key, &value, &size, nil, 0) == 0 else {
            return nil
        }
        let bytes = value.map { UInt8(bitPattern: $0) }
        let endIndex = bytes.firstIndex(of: 0) ?? bytes.endIndex
        return String(decoding: bytes[..<endIndex], as: UTF8.self)
    }
}

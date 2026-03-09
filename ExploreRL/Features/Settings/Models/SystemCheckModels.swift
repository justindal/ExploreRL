import Foundation

struct DeviceInfo {
    var gpuName = "Unavailable"
    var deviceModel = "Unknown"
    var osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    var cpuCores = 0
    var physicalMemoryBytes: UInt64 = 0
    var recommendedMaxWorkingSetBytes: UInt64?
    var currentAllocatedBytes: UInt64?
    var thermalState = "Unknown"
    var lowPowerMode = false

    var physicalMemoryText: String {
        Int64(physicalMemoryBytes).formatted(.byteCount(style: .memory))
    }

    var recommendedMaxWorkingSetText: String {
        guard let recommendedMaxWorkingSetBytes else { return "N/A" }
        return Int64(recommendedMaxWorkingSetBytes).formatted(.byteCount(style: .memory))
    }

    var currentAllocatedText: String {
        guard let currentAllocatedBytes else { return "N/A" }
        return Int64(currentAllocatedBytes).formatted(.byteCount(style: .memory))
    }

    var gpuWorkingSetUtilization: Double? {
        guard let recommendedMaxWorkingSetBytes,
            let currentAllocatedBytes,
            recommendedMaxWorkingSetBytes > 0
        else {
            return nil
        }
        return Double(currentAllocatedBytes) / Double(recommendedMaxWorkingSetBytes)
    }

    var gpuWorkingSetUtilizationText: String {
        guard let gpuWorkingSetUtilization else { return "N/A" }
        return gpuWorkingSetUtilization.formatted(.percent.precision(.fractionLength(0)))
    }
}

enum ReadinessLevel {
    case good
    case attention
    case warning
}

struct ReadinessCheck: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let level: ReadinessLevel
}

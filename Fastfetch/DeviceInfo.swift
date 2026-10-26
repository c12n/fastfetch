import Foundation
import UIKit

/// Read-only system information, gathered with public APIs only.
/// Shared by the Jailbreak app (Fastfetch tab) and the standalone Fastfetch app.
enum DeviceInfo {
    static var machineIdentifier: String {
        var uts = utsname()
        uname(&uts)
        let mirror = Mirror(reflecting: uts.machine)
        return mirror.children.reduce(into: "") { acc, child in
            if let value = child.value as? Int8, value != 0 {
                acc.append(Character(UnicodeScalar(UInt8(value))))
            }
        }
    }

    static var kernelVersion: String {
        var uts = utsname()
        uname(&uts)
        func field(_ mirror: Mirror) -> String {
            mirror.children.reduce(into: "") { acc, child in
                if let value = child.value as? Int8, value != 0 {
                    acc.append(Character(UnicodeScalar(UInt8(value))))
                }
            }
        }
        let sysname = field(Mirror(reflecting: uts.sysname))
        let release = field(Mirror(reflecting: uts.release))
        let version = field(Mirror(reflecting: uts.version))
        return "\(sysname) \(release) — \(version)"
    }

    static var marketingName: String {
        switch machineIdentifier {
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        default: return UIDevice.current.model
        }
    }

    static var socName: String {
        switch machineIdentifier {
        case "iPhone14,7", "iPhone14,8", "iPhone14,2", "iPhone14,3",
             "iPhone14,4", "iPhone14,5", "iPhone14,6":
            return "Apple A15 Bionic"
        case "iPhone15,2", "iPhone15,3":
            return "Apple A16 Bionic"
        default:
            return "arm64e"
        }
    }

    static var iosVersion: String { UIDevice.current.systemVersion }
    static var hostName: String { ProcessInfo.processInfo.hostName }
    static var cpuCores: Int { ProcessInfo.processInfo.processorCount }
    static var activeCpuCores: Int { ProcessInfo.processInfo.activeProcessorCount }

    static var ramString: String {
        let bytes = Double(ProcessInfo.processInfo.physicalMemory)
        return String(format: "%.1f GB", bytes / 1_073_741_824)
    }

    static var storageString: String {
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = (attrs?[.systemSize] as? NSNumber)?.doubleValue ?? 0
        let free = (attrs?[.systemFreeSize] as? NSNumber)?.doubleValue ?? 0
        guard total > 0 else { return "unknown" }
        return String(format: "%.0f GB total, %.0f GB free",
                      total / 1_000_000_000, free / 1_000_000_000)
    }

    static var uptimeString: String {
        let seconds = Int(ProcessInfo.processInfo.systemUptime)
        let d = seconds / 86400, h = (seconds % 86400) / 3600, m = (seconds % 3600) / 60
        if d > 0 { return "\(d)d \(h)h \(m)m" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    /// Paths whose presence indicates an already-jailbroken environment.
    /// In a normal app sandbox these checks are best-effort only.
    static var jailbreakIndicators: [String] {
        let paths = ["/var/jb", "/Applications/Sileo.app", "/Applications/Zebra.app",
                     "/usr/libexec/sshd", "/var/jb/usr/libexec/sshd"]
        return paths.filter { FileManager.default.fileExists(atPath: $0) }
    }

    static var fastfetchText: String {
        """
        \(marketingName) (\(machineIdentifier))
        SoC: \(socName)
        iOS: \(iosVersion)
        Kernel: \(kernelVersion)
        Host: \(hostName)
        CPU: \(cpuCores) cores (\(activeCpuCores) active)
        RAM: \(ramString)
        Storage: \(storageString)
        Uptime: \(uptimeString)
        """
    }
}

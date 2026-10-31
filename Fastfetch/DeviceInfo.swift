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
        case "iPhone18,1": return "iPhone 17 Pro"
        case "iPhone18,2": return "iPhone 17 Pro Max"
        case "iPhone18,3": return "iPhone 17"
        case "iPhone18,4": return "iPhone Air"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,5": return "iPhone 16e"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
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
        case "iPhone18,1", "iPhone18,2", "iPhone18,4":
            return "Apple A19 Pro"
        case "iPhone18,3":
            return "Apple A19"
        case "iPhone17,1", "iPhone17,2":
            return "Apple A18 Pro"
        case "iPhone17,3", "iPhone17,4", "iPhone17,5":
            return "Apple A18"
        case "iPhone16,1", "iPhone16,2":
            return "Apple A17 Pro"
        case "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5":
            return "Apple A16 Bionic"
        case "iPhone14,7", "iPhone14,8", "iPhone14,2", "iPhone14,3",
             "iPhone14,4", "iPhone14,5", "iPhone14,6":
            return "Apple A15 Bionic"
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

    /// The RAM size Apple sells the device with, for the models we know.
    /// `physicalMemory` always reports less than this (the system reserves
    /// some), so the spec figure is the accurate headline and the reported
    /// figure is shown next to it for honesty.
    static var marketedRAMGB: Int? {
        switch machineIdentifier {
        case "iPhone18,1", "iPhone18,2", "iPhone18,4": return 12
        case "iPhone18,3": return 8
        case "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4", "iPhone17,5": return 8
        case "iPhone16,1", "iPhone16,2": return 8
        case "iPhone15,4", "iPhone15,5", "iPhone15,2", "iPhone15,3": return 6
        case "iPhone14,7", "iPhone14,8", "iPhone14,2", "iPhone14,3": return 6
        case "iPhone14,5", "iPhone14,4", "iPhone14,6": return 4
        default: return nil
        }
    }

    static var ramDisplayString: String {
        guard let marketedRAMGB else { return ramString }
        return "\(marketedRAMGB) GB (iOS reports \(ramString))"
    }

    static var storageString: String {
        // Use the volume capacity values iOS Settings itself uses:
        // `volumeAvailableCapacityForImportantUsage` counts purgeable
        // space the system can hand back, so "available" matches what
        // the user can actually use — the old `.systemFreeSize` figure
        // understated it. Fall back to the file-system attributes.
        let home = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? home.resourceValues(forKeys: [.volumeTotalCapacityKey,
                                                            .volumeAvailableCapacityForImportantUsageKey]),
           let total = values.volumeTotalCapacity,
           let available = values.volumeAvailableCapacityForImportantUsage,
           total > 0 {
            return String(format: "%.1f GB total, %.1f GB available",
                          Double(total) / 1_000_000_000,
                          available.doubleValue / 1_000_000_000)
        }
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = (attrs?[.systemSize] as? NSNumber)?.doubleValue ?? 0
        let free = (attrs?[.systemFreeSize] as? NSNumber)?.doubleValue ?? 0
        guard total > 0 else { return "unknown" }
        return String(format: "%.1f GB total, %.1f GB available",
                      total / 1_000_000_000, free / 1_000_000_000)
    }

    /// Display size from the screen itself: points, native pixels and
    /// the maximum refresh rate the panel reports (120 Hz on ProMotion).
    static var displayString: String {
        let screen = UIScreen.main
        // Normalise to portrait (short side × long side) so the spec
        // reads the same in both orientations — the panel doesn't
        // change when the phone rotates, and neither should the row.
        let ptW = min(screen.bounds.width, screen.bounds.height)
        let ptH = max(screen.bounds.width, screen.bounds.height)
        let pxW = min(screen.nativeBounds.width, screen.nativeBounds.height)
        let pxH = max(screen.nativeBounds.width, screen.nativeBounds.height)
        return String(format: "%.0f × %.0f pt · %.0f × %.0f px · %d Hz",
                      ptW, ptH, pxW, pxH,
                      screen.maximumFramesPerSecond)
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

    /// One consistent set of values, captured at a single moment.
    /// The view holds a snapshot and replaces it on refresh — including
    /// the automatic refresh when the device rotates to landscape — so
    /// every row on screen always belongs to the same reading.
    struct Snapshot {
        var deviceName: String
        var machine: String
        var soc: String
        var ios: String
        var kernel: String
        var host: String
        var cpu: String
        var display: String
        var ram: String
        var storage: String
        var battery: String
        var uptime: String

        var shareText: String {
            """
            \(deviceName) (\(machine))
            SoC: \(soc)
            iOS: \(ios)
            Kernel: \(kernel)
            Host: \(host)
            CPU: \(cpu)
            Display: \(display)
            RAM: \(ram)
            Storage: \(storage)
            Battery: \(battery)
            Uptime: \(uptime)
            """
        }

        static func make() -> Snapshot {
            // Battery level reads -1 ("unknown") until monitoring is on,
            // which is why the old build showed Battery: unknown even at
            // 100%. Turn it on *before* reading, every time.
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = UIDevice.current.batteryLevel
            let battery: String
            if level < 0 {
                battery = "unknown"
            } else {
                let pct = Int(level * 100)
                switch UIDevice.current.batteryState {
                case .charging: battery = "\(pct)% (charging)"
                case .full: battery = "\(pct)% (full)"
                default: battery = "\(pct)%"
                }
            }
            return Snapshot(
                deviceName: DeviceInfo.marketingName,
                machine: DeviceInfo.machineIdentifier,
                soc: DeviceInfo.socName,
                ios: DeviceInfo.iosVersion,
                kernel: DeviceInfo.kernelVersion,
                host: DeviceInfo.hostName,
                cpu: "\(DeviceInfo.cpuCores) cores (\(DeviceInfo.activeCpuCores) active)",
                display: DeviceInfo.displayString,
                ram: DeviceInfo.ramDisplayString,
                storage: DeviceInfo.storageString,
                battery: battery,
                uptime: DeviceInfo.uptimeString
            )
        }
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

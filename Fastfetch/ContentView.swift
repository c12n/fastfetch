import SwiftUI
import UIKit

/// Standalone Fastfetch: a neofetch-style system summary for iOS.
/// Everything shown is gathered with public, unprivileged APIs.
struct ContentView: View {
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel
    @State private var batteryState: UIDevice.BatteryState = UIDevice.current.batteryState
    @State private var refreshID = UUID()

    private var batteryText: String {
        guard batteryLevel >= 0 else { return "unknown" }
        let pct = Int(batteryLevel * 100)
        switch batteryState {
        case .charging: return "\(pct)% (charging)"
        case .full: return "\(pct)% (full)"
        case .unplugged: return "\(pct)%"
        default: return "\(pct)%"
        }
    }

    private var logo: String {
        """
           #######
         ###########
        #############  ##
        ##  #######    ####
        ##  ##  ##   ##
            ##  ##  ##
           ####### ##
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(logo)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        row("Device", "\(DeviceInfo.marketingName) (\(DeviceInfo.machineIdentifier))")
                        row("SoC", DeviceInfo.socName)
                        row("iOS", DeviceInfo.iosVersion)
                        row("Kernel", DeviceInfo.kernelVersion)
                        row("Host", DeviceInfo.hostName)
                        row("CPU", "\(DeviceInfo.cpuCores) cores (\(DeviceInfo.activeCpuCores) active)")
                        row("RAM", DeviceInfo.ramString)
                        row("Storage", DeviceInfo.storageString)
                        row("Battery", batteryText)
                        row("Uptime", DeviceInfo.uptimeString)
                    }
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)

                    HStack(spacing: 12) {
                        Button {
                            refreshID = UUID()
                            batteryLevel = UIDevice.current.batteryLevel
                            batteryState = UIDevice.current.batteryState
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)

                        ShareLink(item: DeviceInfo.fastfetchText + "\nBattery: \(batteryText)") {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .id(refreshID)
            }
            .navigationTitle("Fastfetch")
        }
        .onAppear { UIDevice.current.isBatteryMonitoringEnabled = true }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(key)
                .foregroundStyle(.cyan)
                .frame(width: 64, alignment: .leading)
            Text(value)
        }
    }
}

#Preview {
    ContentView()
}

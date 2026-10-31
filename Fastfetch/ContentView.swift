import Combine
import SwiftUI
import UIKit

/// Standalone Fastfetch: a neofetch-style system summary for iOS.
/// Everything shown is gathered with public, unprivileged APIs.
///
/// Layout is adaptive:
/// - Portrait: Apple logo on top, info cards below.
/// - Landscape: Apple logo in a left panel, info cards on the right —
///   the classic fastfetch side-by-side look, with no squeezed labels.
/// Rotating into landscape (or opening the app in landscape) refreshes
/// the snapshot automatically, so uptime / battery / storage are fresh.
struct ContentView: View {
    @State private var snapshot = DeviceInfo.Snapshot.make()
    @State private var lastRefreshed = Date()
    @State private var wasLandscape = false

    // MARK: - Apple logo ASCII art

    /// The Apple logo, drawn with `#` characters: leaf on top,
    /// a dip between the two lobes, and the bite on the right.
    /// Every line is rendered on its own with `lineLimit(1)` and a
    /// font size fitted to the available width, so the art can
    /// never wrap, hyphenate or skew in any orientation.
    private static let logoLines: [String] = [
        "                 ####",
        "               ########",
        "                ####",
        "      #######  #########",
        "    #####################",
        "   ######################",
        "  #######################",
        "  ####################",
        "  ##################",
        "  ####################",
        "   ####################",
        "    ##################",
        "     ################",
        "       ######  ######",
    ]

    private static var logoMaxWidth: CGFloat {
        CGFloat(logoLines.map(\.count).max() ?? 0)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                background

                if isLandscape {
                    landscapeLayout(width: geo.size.width, height: geo.size.height)
                        .onAppear { refresh() }
                } else {
                    portraitLayout(width: geo.size.width)
                }
            }
            .onChange(of: isLandscape) { _, newValue in
                // Auto-refresh the moment the phone is turned to landscape.
                if newValue && !wasLandscape {
                    refresh()
                }
                wasLandscape = newValue
            }
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                wasLandscape = isLandscape
                refresh()
            }
            // Keep the battery reading accurate while the app is open:
            // refresh as soon as iOS reports a level or state change
            // (plugged in, unplugged, crossed a percentage).
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
                refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
                refresh()
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.04, green: 0.07, blue: 0.12),
                     Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Portrait

    private func portraitLayout(width: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                logoCard(width: width - 32)
                infoCards
                actionButtons
                refreshedLabel
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Landscape

    private func landscapeLayout(width: CGFloat, height: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left panel: logo, title and refresh time stay visible
            // while the info on the right scrolls.
            VStack(spacing: 10) {
                Spacer(minLength: 0)
                logoView(width: width * 0.36)
                Text("Fastfetch")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                refreshedLabel
                Spacer(minLength: 0)
            }
            .frame(width: width * 0.38, height: height)
            .background(cardBackground)

            ScrollView {
                VStack(spacing: 12) {
                    infoCards
                    actionButtons
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fastfetch")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text(snapshot.deviceName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "apple.logo")
                .font(.title2)
                .foregroundStyle(.cyan)
        }
    }

    private func logoCard(width: CGFloat) -> some View {
        logoView(width: width)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(cardBackground)
    }

    /// Apple logo fitted to `width`: the font size is derived from the
    /// longest line, so the art always fits on one line per row and
    /// never wraps or breaks up.
    private func logoView(width: CGFloat) -> some View {
        // A monospaced glyph is about 0.6x the point size wide.
        let fontSize = min(20, max(9, (width - 24) / (Self.logoMaxWidth * 0.6)))
        return VStack(spacing: 0) {
            ForEach(Array(Self.logoLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
        .accessibilityHidden(true)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.09), lineWidth: 1)
            )
    }

    // MARK: - Info cards

    private var infoCards: some View {
        VStack(spacing: 12) {
            card(title: "Device", rows: [
                .init(label: "Device", value: "\(snapshot.deviceName) (\(snapshot.machine))", icon: "iphone"),
                .init(label: "SoC", value: snapshot.soc, icon: "cpu"),
                .init(label: "CPU", value: snapshot.cpu, icon: "waveform.path.ecg"),
                .init(label: "Display", value: snapshot.display, icon: "display"),
                .init(label: "RAM", value: snapshot.ram, icon: "memorychip"),
            ])
            card(title: "System", rows: [
                .init(label: "iOS", value: snapshot.ios, icon: "apple.logo"),
                .init(label: "Kernel", value: snapshot.kernel, icon: "terminal"),
                .init(label: "Host", value: snapshot.host, icon: "network"),
                .init(label: "Uptime", value: snapshot.uptime, icon: "clock"),
            ])
            card(title: "Storage & Power", rows: [
                .init(label: "Storage", value: snapshot.storage, icon: "internaldrive"),
                .init(label: "Battery", value: snapshot.battery, icon: "battery.75percent"),
            ])
        }
    }

    private struct InfoRow: Identifiable {
        let label: String
        let value: String
        let icon: String
        var id: String { label }
    }

    private func card(title: String, rows: [InfoRow]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.cyan)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: row.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.cyan)
                        .frame(width: 32, height: 32)
                        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    // Label stacked above the value: the label always gets
                    // its full word on one line (no "Stor-age" / "Bat-tery"
                    // wrapping) and long values like the kernel string get
                    // the full width of the card to wrap in.
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                        Text(row.value)
                            .font(.system(.subheadline, design: .monospaced).weight(.medium))
                            .foregroundStyle(.white)
                            .textSelection(.enabled)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)

                if index < rows.count - 1 {
                    Divider()
                        .overlay(.white.opacity(0.07))
                        .padding(.leading, 60)
                        .padding(.trailing, 16)
                }
            }
            .padding(.bottom, 6)
        }
        .background(cardBackground)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .foregroundStyle(.black)

            ShareLink(item: snapshot.shareText) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .tint(.cyan)
        }
    }

    private var refreshedLabel: some View {
        Text("Updated \(lastRefreshed.formatted(date: .omitted, time: .standard))")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.45))
            .lineLimit(1)
    }

    // MARK: - Refresh

    private func refresh() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        snapshot = DeviceInfo.Snapshot.make()
        lastRefreshed = Date()
    }
}

#Preview {
    ContentView()
}

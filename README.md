# Fastfetch for iOS

A tiny, fast, neofetch-style system information app for iPhone and iPad.
Shows the info you actually want at a glance — device model and identifier,
SoC, iOS version, kernel version, hostname, CPU cores, RAM, storage,
battery and uptime — in a clean terminal-style view.

Everything is gathered with **public, unprivileged APIs** (`uname`,
`ProcessInfo`, `FileManager`, `UIDevice`). No entitlements, no jailbreak,
no data collection. What you see is computed on device, on the spot.

## Features

- Apple logo ASCII art, sized to fit the screen so it never wraps or skews
- Device marketing name + hardware identifier (e.g. `iPhone 17 Pro Max (iPhone18,2)`)
- SoC name for A15–A19 devices, generic fallback elsewhere
- iOS version and full Darwin kernel version string
- CPU core count, display (points / native pixels / max Hz), RAM
  (marketed size plus the figure iOS reports), storage using the same
  volume-capacity values as iOS Settings, battery level/state, uptime
- Beautiful grouped info cards with the label stacked above each value,
  so no label ever wraps mid-word
- Adaptive landscape layout: logo panel on the left, info on the right,
  fastfetch-style — and rotating into landscape refreshes automatically
- Battery readings stay live (refresh on level/state changes)
- Refresh on demand, share the summary as text
- Native Light/Dark Mode

## Install

Download `Fastfetch.ipa` from the
[Releases](https://github.com/c12n/fastfetch/releases) page and sideload it
with your preferred tool (AltStore, SideStore, Sideloadly, etc.). The IPA is
**unsigned**, so your sideloading tool signs it with your Apple ID.

## Build

- Open `Fastfetch.xcodeproj` in Xcode 16+ and run, or
- Push to GitHub: the bundled Actions workflow builds an unsigned IPA on a
  macOS runner and uploads it as a build artifact.

Requires iOS 17.0+.

## License

MIT — Copyright (c) 2026 c12n Apps

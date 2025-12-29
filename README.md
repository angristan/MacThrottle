# MacThrottle (Pre-macOS 26 Fork)

> **Fork Notice:** This is a fork of [angristan/MacThrottle](https://github.com/angristan/MacThrottle) for users running **macOS 15+** who haven't upgraded to macOS 26 (Tahoe) yet. The original project requires macOS 26 for new UI features (glassEffect). This fork maintains compatibility with macOS 15 (Sequoia) and later pre-26 versions.
>
> **macOS 26+ (Tahoe) kullanıcıları:** [angristan/MacThrottle](https://github.com/angristan/MacThrottle/releases) reposundan orijinal sürümü indirin.

[![GitHub Release](https://img.shields.io/github/v/release/trkaplan/MacThrottle)](https://github.com/trkaplan/MacThrottle/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-15+-blue)](https://github.com/trkaplan/MacThrottle)
[![Swift](https://img.shields.io/badge/Swift-6-orange)](https://swift.org)

A lightweight macOS menu bar app that monitors thermal pressure and alerts you when your Mac is being throttled. No admin privileges required.

| This Fork (macOS 15+) | Original (macOS 26+) |
|:---------------------:|:--------------------:|
| ![pre26](./assets/screenshot-pre26-fork.png) | ![original](./assets/screenshot.png) |

## Features

- Displays thermal pressure state in the menu bar using different thermometer icons
- Shows CPU core temperature (reads directly from SMC)
- Shows fan speed percentage (on Macs with fans)
- History graph showing thermal state, temperature, and fan speed over the last 10 minutes
- Statistics showing time spent in each thermal state
- Configurable notifications:
  - When heavy throttling begins
  - When critical throttling occurs
  - When throttling stops (recovery)
  - Optional notification sounds
- Launch at Login option
- No helper daemon or admin privileges required

## Thermal States

| Icon                   | State    | Description               |
| ---------------------- | -------- | ------------------------- |
| `thermometer.low`      | Nominal  | Normal operation          |
| `thermometer.medium`   | Moderate | Elevated thermal pressure |
| `thermometer.high`     | Heavy    | Active throttling         |
| `thermometer.sun.fill` | Critical | Severe throttling         |

## Installation

| macOS Version | Download From |
|---------------|---------------|
| **macOS 15-25** (pre-Tahoe) | [trkaplan/MacThrottle](https://github.com/trkaplan/MacThrottle/releases) (this fork) |
| **macOS 26+** (Tahoe) | [angristan/MacThrottle](https://github.com/angristan/MacThrottle/releases) (original) |

Since the app is not signed, Gatekeeper may block it on first launch. You can either download a pre-built version from Releases and remove the quarantine attribute, or build it locally with Xcode to sign it with your own certificate.

### Option 1: Download from Releases

> **Note:** This fork is for **macOS 15-25**. If you're on **macOS 26+**, download from [angristan/MacThrottle](https://github.com/angristan/MacThrottle/releases) instead.

1. Download the latest `.dmg` from [Releases](https://github.com/trkaplan/MacThrottle/releases)
2. Open it, and drag `MacThrottle.app` to your Applications folder
3. Remove quarantine attribute: `xattr -r -d com.apple.quarantine /Applications/MacThrottle.app`
4. Open the app

### Option 2: Build Locally

Building locally automatically signs the app with your development certificate, avoiding Gatekeeper issues.

```bash
# Clone the repo
git clone https://github.com/trkaplan/MacThrottle.git
cd MacThrottle

# Build with Xcode
xcodebuild -project MacThrottle.xcodeproj \
  -scheme MacThrottle \
  -configuration Release \
  -derivedDataPath build

# Run the app
open build/Build/Products/Release/MacThrottle.app
```

Or open `MacThrottle.xcodeproj` in Xcode and press `Cmd+R` to build and run.

## How It Works

### Thermal Pressure

MacThrottle reads thermal pressure using the Darwin notification system ([`notify_get_state`](https://developer.apple.com/documentation/darwinnotify/notify_get_state)), specifically the `com.apple.system.thermalpressurelevel` notification. The system reports 5 levels (nominal, moderate, heavy, trapping, sleeping), but MacThrottle consolidates the last two into "critical" since they're rarely reached in practice. Heavy is where throttling really kicks in.

> **Note:** This notification name is not publicly documented by Apple. It comes from the private [`OSThermalNotification.h`](https://github.com/tripleCC/Laboratory/blob/a7d1192f25d718e3b01a015ca35bfcef4419e883/AppleSources/Libc-1272.250.1/include/libkern/OSThermalNotification.h#L44-L48) header (as `kOSThermalNotificationPressureLevelName`) and has been available since macOS 10.10. See [Thermals and macOS](https://dmaclach.medium.com/thermals-and-macos-c0db81062889) for more details on macOS thermal APIs.
> You can see it implemented [in Bazel for example](https://github.com/bazelbuild/bazel/blob/83bddd49aae9e42b4aff1c79c4f437a31b9aec8c/src/main/native/darwin/system_thermal_monitor_jni.cc#L27).

#### Why not `ProcessInfo.thermalState`?

macOS provides [`ProcessInfo.thermalState`](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum) as a public API, but it has limited granularity (only 4 states vs the 5 actual pressure levels):

| `ProcessInfo.thermalState` | Actual Pressure Level |
| -------------------------- | --------------------- |
| nominal                    | nominal               |
| **fair**                   | **moderate**          |
| **fair**                   | **heavy**             |
| serious                    | trapping              |
| critical                   | sleeping              |

The `moderate` and `heavy` states both map to `fair` in `ProcessInfo.thermalState`, but the difference is significant: `heavy` is when throttling really kicks in. MacThrottle provides this granularity.

### Temperature Reading

MacThrottle displays temperature alongside thermal pressure. Reported temperature is the maxmium of all CPU/GPU core temperatures.

It's using two methods:

#### SMC (Primary)

The **System Management Controller (SMC)** is a hardware chip in every Mac that manages thermal sensors, fans, and power. MacThrottle reads directly from the SMC via IOKit to get actual CPU core temperatures.

- Reads chip-specific sensor keys (different for M1, M2, M3, etc)
- Provides accurate per-core temperature readings
- Based on the approach used by [Stats](https://github.com/exelban/stats)

#### IOHIDEventSystem (Fallback)

If SMC reading fails, MacThrottle falls back to the **IOHIDEventSystem** private API:

- Reads temperature events from PMU (Power Management Unit) sensors
- Simpler but less granular: returns aggregate "tdie" temperatures rather than per-core values
- May report slightly different (typically lower) values than SMC

The displayed temperature is the maximum reading across all available CPU sensors.

### Fan Speed

On Macs with fans, MacThrottle reads fan speed from the SMC using standard fan keys (`FNum` for count, `F0Ac`/`F1Ac` for actual RPM, `F0Mx`/`F1Mx` for maximum RPM). The speed is displayed as a percentage of maximum capacity and shown as a dashed cyan line on the history graph.

Fanless Macs (like MacBook Air) won't show fan data or the "Show Fan Speed" toggle.

## Requirements

- macOS 15.0+ (Sequoia) — for macOS 26+, use [angristan/MacThrottle](https://github.com/angristan/MacThrottle)

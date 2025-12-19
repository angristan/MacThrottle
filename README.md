# MacThrottle

A macOS menu bar app that monitors thermal pressure and alerts you when your Mac is being throttled.

![screenshot](./assets/screenshot.png)

## Features

- Displays thermal pressure state in the menu bar using different thermometer icons
- Shows CPU core temperature (reads directly from SMC)
- History graph showing thermal state and temperature over the last 10 minutes
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

### Option 1: Download from Releases

1. Download the latest `.dmg` from [Releases](https://github.com/angristan/MacThrottle/releases)
2. Drag `MacThrottle.app` to your Applications folder
3. Right-click the app → "Open" → "Open" (required for unsigned apps)

### Option 2: Build Locally

Building locally automatically signs the app with your development certificate, avoiding Gatekeeper issues.

```bash
# Clone the repo
git clone https://github.com/angristan/MacThrottle.git
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

MacThrottle displays CPU temperature alongside thermal pressure using two methods:

#### SMC (Primary)

The **System Management Controller (SMC)** is a hardware chip in every Mac that manages thermal sensors, fans, and power. MacThrottle reads directly from the SMC via IOKit to get actual CPU core temperatures.

- Reads chip-specific sensor keys (different for M1, M2, M3)
- Provides accurate per-core temperature readings
- Based on the approach used by [Stats](https://github.com/exelban/stats)

#### IOHIDEventSystem (Fallback)

If SMC reading fails, MacThrottle falls back to the **IOHIDEventSystem** private API:

- Reads temperature events from PMU (Power Management Unit) sensors
- Simpler but less granular: returns aggregate "tdie" temperatures rather than per-core values
- May report slightly different (typically lower) values than SMC

The displayed temperature is the maximum reading across all available CPU sensors.

## Requirements

- macOS 26.0+ (Tahoe)

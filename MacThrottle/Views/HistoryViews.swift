import SwiftUI

private struct WidthPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HistoryGraphView: View {
    // MARK: - Constants
    private static let maxPoints = 300
    private static let minTemperatureBound: Double = 30
    private static let maxTemperatureBound: Double = 110
    private static let temperaturePadding: Double = 5

    // MARK: - Properties
    let history: [HistoryEntry]
    var showFanSpeed: Bool = true
    @State private var hoverLocation: CGPoint?

    private var historyDuration: TimeInterval {
        guard let first = history.first else { return 0 }
        return Date().timeIntervalSince(first.timestamp)
    }

    private var downsampledHistory: [HistoryEntry] {
        guard history.count > Self.maxPoints else { return history }

        let step = Double(history.count) / Double(Self.maxPoints)
        var result: [HistoryEntry] = []
        result.reserveCapacity(Self.maxPoints)

        for i in 0..<Self.maxPoints {
            let index = min(Int(Double(i) * step), history.count - 1)
            result.append(history[index])
        }

        if let last = history.last, result.last?.timestamp != last.timestamp {
            result[result.count - 1] = last
        }

        return result
    }

    private var temperatureRange: (min: Double, max: Double) {
        let temps = downsampledHistory.compactMap { $0.temperature }
        guard !temps.isEmpty else { return (Self.minTemperatureBound, 100) }
        let minTemp = max(Self.minTemperatureBound, (temps.min() ?? Self.minTemperatureBound) - Self.temperaturePadding)
        let maxTemp = min(Self.maxTemperatureBound, (temps.max() ?? 100) + Self.temperaturePadding)
        return (minTemp, maxTemp)
    }

    private var hasFanData: Bool {
        showFanSpeed && downsampledHistory.contains { $0.fanSpeed != nil }
    }

    private func yPositionForTemperature(_ temp: Double, height: CGFloat) -> CGFloat {
        let range = temperatureRange
        let padding: CGFloat = 4
        let normalized = (temp - range.min) / (range.max - range.min)
        return padding + (1.0 - CGFloat(normalized)) * (height - padding * 2)
    }

    private func yPositionForFanSpeed(_ percentage: Double, height: CGFloat) -> CGFloat {
        let padding: CGFloat = 4
        let normalized = percentage / 100.0
        return padding + (1.0 - CGFloat(normalized)) * (height - padding * 2)
    }

    private func entryAt(x: CGFloat, width: CGFloat) -> HistoryEntry? {
        guard history.count >= 2, let first = history.first else { return nil }
        let totalDuration = Date().timeIntervalSince(first.timestamp)
        guard totalDuration > 0 else { return nil }

        let fraction = x / width
        let targetTime = first.timestamp.addingTimeInterval(totalDuration * fraction)

        // Find the last entry whose timestamp is <= targetTime (the segment we're in)
        return history.last { $0.timestamp <= targetTime } ?? history.first
    }

    @State private var graphWidth: CGFloat = 220

    var body: some View {
        VStack(spacing: 2) {
            graphView
                .background(GeometryReader { geo in
                    Color.clear.preference(key: WidthPreferenceKey.self, value: geo.size.width)
                })
                .onPreferenceChange(WidthPreferenceKey.self) { graphWidth = $0 }
                .overlay(alignment: .topTrailing) {
                    tooltipView
                }

            HStack {
                Text(formatTimeAgo(historyDuration))
                Spacer()
                Text("now")
            }
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
        }
    }

    private var graphView: some View {
        Canvas { context, size in
            let sampled = downsampledHistory
            guard sampled.count >= 2 else { return }

            guard let firstEntry = sampled.first else { return }
            let startTime = firstEntry.timestamp
            let endTime = Date()
            let totalDuration = endTime.timeIntervalSince(startTime)

            guard totalDuration > 0 else { return }

            // Draw thermal pressure background as merged segments by pressure state
            var currentPressure = sampled[0].pressure
            var segmentStart: CGFloat = 0

            for i in 0..<sampled.count {
                let entry = sampled[i]
                let x = CGFloat(entry.timestamp.timeIntervalSince(startTime) / totalDuration) * size.width

                if entry.pressure != currentPressure {
                    let rect = CGRect(x: segmentStart, y: 0, width: x - segmentStart, height: size.height)
                    context.fill(Path(rect), with: .color(currentPressure.color.opacity(0.3)))
                    currentPressure = entry.pressure
                    segmentStart = x
                }
            }
            // Draw final segment to end
            let finalRect = CGRect(x: segmentStart, y: 0, width: size.width - segmentStart, height: size.height)
            context.fill(Path(finalRect), with: .color(currentPressure.color.opacity(0.3)))

            // Draw temperature line
            var tempPath = Path()
            var firstPoint = true

            for entry in sampled {
                guard let temp = entry.temperature else { continue }

                let x = CGFloat(entry.timestamp.timeIntervalSince(startTime) / totalDuration) * size.width
                let y = yPositionForTemperature(temp, height: size.height)

                if firstPoint {
                    tempPath.move(to: CGPoint(x: x, y: y))
                    firstPoint = false
                } else {
                    tempPath.addLine(to: CGPoint(x: x, y: y))
                }
            }

            if let last = sampled.last, let temp = last.temperature {
                let y = yPositionForTemperature(temp, height: size.height)
                tempPath.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(tempPath, with: .color(.primary.opacity(0.8)), lineWidth: 1.5)

            // Draw fan speed line (if data available)
            let fanColor = Color.cyan
            if hasFanData {
                var fanPath = Path()
                var firstFanPoint = true

                for entry in sampled {
                    guard let fan = entry.fanSpeed else { continue }

                    let x = CGFloat(entry.timestamp.timeIntervalSince(startTime) / totalDuration) * size.width
                    let y = yPositionForFanSpeed(fan, height: size.height)

                    if firstFanPoint {
                        fanPath.move(to: CGPoint(x: x, y: y))
                        firstFanPoint = false
                    } else {
                        fanPath.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                if let last = sampled.last, let fan = last.fanSpeed {
                    let y = yPositionForFanSpeed(fan, height: size.height)
                    fanPath.addLine(to: CGPoint(x: size.width, y: y))
                }

                context.stroke(
                    fanPath,
                    with: .color(fanColor.opacity(0.5)),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 2])
                )

                // Current fan speed point (smaller)
                if let last = sampled.last, let fan = last.fanSpeed {
                    let y = yPositionForFanSpeed(fan, height: size.height)
                    let circle = Path(ellipseIn: CGRect(x: size.width - 3, y: y - 3, width: 6, height: 6))
                    context.fill(circle, with: .color(fanColor.opacity(0.7)))
                }
            }

            // Current temperature point
            if let last = sampled.last, let temp = last.temperature {
                let y = yPositionForTemperature(temp, height: size.height)
                let circle = Path(ellipseIn: CGRect(x: size.width - 4, y: y - 4, width: 8, height: 8))
                context.fill(circle, with: .color(.primary))
            }

            // Temperature range labels (left side)
            let range = temperatureRange
            let labelStyle = Font.system(size: 8)
            let labelColor = Color.secondary.opacity(0.8)
            let maxLabel = Text("\(Int(range.max))°").font(labelStyle).foregroundColor(labelColor)
            let minLabel = Text("\(Int(range.min))°").font(labelStyle).foregroundColor(labelColor)
            context.draw(maxLabel, at: CGPoint(x: 4, y: 4), anchor: .topLeading)
            context.draw(minLabel, at: CGPoint(x: 4, y: size.height - 4), anchor: .bottomLeading)

            // Fan speed range labels (right side)
            if hasFanData {
                let fanMaxLabel = Text("100%").font(labelStyle).foregroundColor(fanColor.opacity(0.8))
                let fanMinLabel = Text("0%").font(labelStyle).foregroundColor(fanColor.opacity(0.8))
                context.draw(fanMaxLabel, at: CGPoint(x: size.width - 4, y: 4), anchor: .topTrailing)
                context.draw(fanMinLabel, at: CGPoint(x: size.width - 4, y: size.height - 4), anchor: .bottomTrailing)
            }

            // Hover indicator
            if let location = hoverLocation, let entry = entryAt(x: location.x, width: size.width) {
                var linePath = Path()
                linePath.move(to: CGPoint(x: location.x, y: 0))
                linePath.addLine(to: CGPoint(x: location.x, y: size.height))
                context.stroke(linePath, with: .color(.primary.opacity(0.3)), lineWidth: 1)

                // Temperature hover point
                if let temp = entry.temperature {
                    let y = yPositionForTemperature(temp, height: size.height)
                    let circle = Path(ellipseIn: CGRect(x: location.x - 4, y: y - 4, width: 8, height: 8))
                    context.fill(circle, with: .color(entry.pressure.color))
                    context.stroke(circle, with: .color(.primary), lineWidth: 1.5)
                }

                // Fan speed hover point (smaller, subtler)
                if hasFanData, let fan = entry.fanSpeed {
                    let y = yPositionForFanSpeed(fan, height: size.height)
                    let circle = Path(ellipseIn: CGRect(x: location.x - 3, y: y - 3, width: 6, height: 6))
                    context.fill(circle, with: .color(fanColor.opacity(0.8)))
                    context.stroke(circle, with: .color(.primary.opacity(0.6)), lineWidth: 1)
                }
            }
        }
        .frame(height: 70)
        .drawingGroup()
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.secondary.opacity(0.3), lineWidth: 1))
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                hoverLocation = location
            case .ended:
                hoverLocation = nil
            }
        }
    }

    @ViewBuilder
    private var tooltipView: some View {
        if let location = hoverLocation, let entry = entryAt(x: location.x, width: graphWidth) {
            if let temp = entry.temperature {
                let timeAgo = Int(Date().timeIntervalSince(entry.timestamp))
                let timeStr = timeAgo < 60 ? "\(timeAgo)s ago" : "\(timeAgo / 60)m ago"
                let fanStr = showFanSpeed ? entry.fanSpeed.map { " • Fan \(Int($0))%" } ?? "" : ""
                if #available(macOS 26.0, *) {
                    Text("\(Int(temp))° • \(entry.pressure.displayName)\(fanStr) • \(timeStr)")
                        .font(.system(size: 8, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 6))
                        .padding(4)
                } else {
                    Text("\(Int(temp))° • \(entry.pressure.displayName)\(fanStr) • \(timeStr)")
                        .font(.system(size: 8, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        .padding(4)
                }
            }
        }
    }

    private func formatTimeAgo(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h ago"
            }
            return "\(hours)h \(mins)m ago"
        }
    }
}

struct TimeBreakdownView: View {
    let timeInEachState: [(pressure: ThermalPressure, duration: TimeInterval)]
    let totalDuration: TimeInterval

    private static let allStates: [ThermalPressure] = [.nominal, .moderate, .heavy, .critical]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Self.allStates, id: \.self) { pressure in
                let duration = timeInEachState.first { $0.pressure == pressure }?.duration ?? 0
                HStack {
                    Circle()
                        .fill(pressure.color)
                        .frame(width: 8, height: 8)
                    HStack(spacing: 2) {
                        Text(pressure.displayName)
                        if pressure.isThrottling {
                            Text("(throttling)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(formatDuration(duration))
                        .foregroundStyle(.secondary)
                    if totalDuration > 0 {
                        let percentage = (duration / totalDuration * 100).rounded()
                        Text("(\(Int(percentage))%)")
                            .foregroundStyle(.secondary)
                            .frame(width: 45, alignment: .trailing)
                    }
                }
                .font(.caption)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

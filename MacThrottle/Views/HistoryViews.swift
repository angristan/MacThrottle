import SwiftUI

struct HistoryGraphView: View {
    let history: [HistoryEntry]
    @State private var hoverLocation: CGPoint?

    private let maxPoints = 300

    private var historyDuration: TimeInterval {
        guard let first = history.first else { return 0 }
        return Date().timeIntervalSince(first.timestamp)
    }

    private var downsampledHistory: [HistoryEntry] {
        guard history.count > maxPoints else { return history }

        let step = Double(history.count) / Double(maxPoints)
        var result: [HistoryEntry] = []
        result.reserveCapacity(maxPoints)

        for i in 0..<maxPoints {
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
        guard !temps.isEmpty else { return (30, 100) }
        let minTemp = max(30, (temps.min() ?? 30) - 5)
        let maxTemp = min(110, (temps.max() ?? 100) + 5)
        return (minTemp, maxTemp)
    }

    private func yPositionForTemperature(_ temp: Double, height: CGFloat) -> CGFloat {
        let range = temperatureRange
        let padding: CGFloat = 4
        let normalized = (temp - range.min) / (range.max - range.min)
        return padding + (1.0 - CGFloat(normalized)) * (height - padding * 2)
    }

    private func entryAt(x: CGFloat, width: CGFloat) -> HistoryEntry? {
        guard history.count >= 2, let first = history.first else { return nil }
        let totalDuration = Date().timeIntervalSince(first.timestamp)
        guard totalDuration > 0 else { return nil }

        let fraction = x / width
        let targetTime = first.timestamp.addingTimeInterval(totalDuration * fraction)

        return history.min { entry1, entry2 in
            abs(entry1.timestamp.timeIntervalSince(targetTime)) <
                abs(entry2.timestamp.timeIntervalSince(targetTime))
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Canvas { context, size in
                let sampled = downsampledHistory
                guard sampled.count >= 2 else { return }

                guard let firstEntry = sampled.first else { return }
                let startTime = firstEntry.timestamp
                let endTime = Date()
                let totalDuration = endTime.timeIntervalSince(startTime)

                guard totalDuration > 0 else { return }

                // Draw thermal pressure background segments
                for i in 0..<(sampled.count - 1) {
                    let current = sampled[i]
                    let next = sampled[i + 1]

                    let startFraction = current.timestamp.timeIntervalSince(startTime) / totalDuration
                    let endFraction = next.timestamp.timeIntervalSince(startTime) / totalDuration
                    let startX = floor(CGFloat(startFraction) * size.width)
                    let endX = ceil(CGFloat(endFraction) * size.width)

                    let rect = CGRect(x: startX, y: 0, width: max(endX - startX, 1), height: size.height)
                    context.fill(Path(rect), with: .color(current.pressure.color.opacity(0.3)))
                }

                // Draw last segment to now
                if let last = sampled.last {
                    let lastFraction = last.timestamp.timeIntervalSince(startTime) / totalDuration
                    let startX = floor(CGFloat(lastFraction) * size.width)
                    let rect = CGRect(x: startX, y: 0, width: size.width - startX, height: size.height)
                    context.fill(Path(rect), with: .color(last.pressure.color.opacity(0.3)))
                }

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

                // Current temperature point
                if let last = sampled.last, let temp = last.temperature {
                    let y = yPositionForTemperature(temp, height: size.height)
                    let circle = Path(ellipseIn: CGRect(x: size.width - 4, y: y - 4, width: 8, height: 8))
                    context.fill(circle, with: .color(.primary))
                }

                // Temperature range labels
                let range = temperatureRange
                let labelStyle = Font.system(size: 8)
                let labelColor = Color.secondary.opacity(0.8)
                let maxLabel = Text("\(Int(range.max))°").font(labelStyle).foregroundColor(labelColor)
                let minLabel = Text("\(Int(range.min))°").font(labelStyle).foregroundColor(labelColor)
                context.draw(maxLabel, at: CGPoint(x: 4, y: 4), anchor: .topLeading)
                context.draw(minLabel, at: CGPoint(x: 4, y: size.height - 4), anchor: .bottomLeading)

                // Hover indicator
                if let location = hoverLocation, let entry = entryAt(x: location.x, width: size.width) {
                    var linePath = Path()
                    linePath.move(to: CGPoint(x: location.x, y: 0))
                    linePath.addLine(to: CGPoint(x: location.x, y: size.height))
                    context.stroke(linePath, with: .color(.primary.opacity(0.3)), lineWidth: 1)

                    if let temp = entry.temperature {
                        let y = yPositionForTemperature(temp, height: size.height)
                        let circle = Path(ellipseIn: CGRect(x: location.x - 4, y: y - 4, width: 8, height: 8))
                        context.fill(circle, with: .color(entry.pressure.color))
                        context.stroke(circle, with: .color(.primary), lineWidth: 1.5)
                    }
                }
            }
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.secondary.opacity(0.3), lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                if let location = hoverLocation, let entry = entryAt(x: location.x, width: 220) {
                    if let temp = entry.temperature {
                        let timeAgo = Int(Date().timeIntervalSince(entry.timestamp))
                        let timeStr = timeAgo < 60 ? "\(timeAgo)s ago" : "\(timeAgo / 60)m ago"
                        Text("\(Int(temp))° • \(entry.pressure.displayName) • \(timeStr)")
                            .font(.system(size: 8, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundColor(.white)
                            .padding(4)
                    }
                }
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverLocation = location
                case .ended:
                    hoverLocation = nil
                }
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

    private static let allStates: [ThermalPressure] = [.nominal, .moderate, .heavy, .trapping, .sleeping]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Self.allStates, id: \.self) { pressure in
                let duration = timeInEachState.first { $0.pressure == pressure }?.duration ?? 0
                HStack {
                    Circle()
                        .fill(pressure.color)
                        .frame(width: 8, height: 8)
                    Text(pressure.displayName)
                        .frame(width: 60, alignment: .leading)
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

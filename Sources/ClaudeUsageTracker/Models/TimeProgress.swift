import Foundation

enum TimeProgress {
    static func elapsedFraction(resetsAt: Date, windowLength: TimeInterval, now: Date = Date()) -> Double {
        let start = resetsAt.addingTimeInterval(-windowLength)
        let elapsed = now.timeIntervalSince(start)
        return min(max(elapsed / windowLength, 0), 1)
    }

    static func elapsedString(resetsAt: Date, windowLength: TimeInterval, now: Date = Date()) -> String {
        let start = resetsAt.addingTimeInterval(-windowLength)
        let elapsed = max(now.timeIntervalSince(start), 0)
        if windowLength >= 24 * 3600 {
            let days = Int(elapsed) / 86_400
            let hours = (Int(elapsed) % 86_400) / 3600
            return "\(days)d \(hours)h elapsed"
        } else {
            let hours = Int(elapsed) / 3600
            let minutes = (Int(elapsed) % 3600) / 60
            return "\(hours)h \(minutes)m elapsed"
        }
    }

    /// A short relative countdown to the reset, e.g. "in 1h 9m" or "in 2d 5h".
    static func resetsInString(resetsAt: Date, now: Date = Date()) -> String {
        let remaining = max(resetsAt.timeIntervalSince(now), 0)
        if remaining >= 24 * 3600 {
            let days = Int(remaining) / 86_400
            let hours = (Int(remaining) % 86_400) / 3600
            return "in \(days)d \(hours)h"
        } else if remaining >= 3600 {
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(Int(remaining) / 60)m"
        }
    }

    static func resetString(resetsAt: Date, now: Date = Date()) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDate(resetsAt, inSameDayAs: now) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "EEE"
        }
        return "resets \(formatter.string(from: resetsAt))"
    }
}

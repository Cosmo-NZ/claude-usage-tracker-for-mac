import SwiftUI

struct UsageBar: View {
    let kind: WindowKind
    let usage: WindowUsage?
    let hasError: Bool
    var tint: Color = .usageGreen
    var emptyText: String = "Not connected"

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                // Model-specific rows get a leading color dot to set them apart.
                if kind == .sevenDayOpus || kind == .weeklyFable {
                    Circle().fill(barColor).frame(width: 7, height: 7)
                }
                Text(kind.title).font(.system(size: 15, weight: .bold))
                if hasError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow).font(.system(size: 11))
                }
                Spacer()
                Text(usage.map { "\(Int($0.utilization * 100))%" } ?? "—")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(usage == nil ? .secondary : barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12)).frame(height: 9)
                    Capsule().fill(barColor)
                        .frame(width: geo.size.width * (usage?.utilization ?? 0), height: 9)
                    if let usage {
                        // Time-elapsed marker: how far through the window we are, for pacing.
                        let elapsed = TimeProgress.elapsedFraction(resetsAt: usage.resetsAt, windowLength: usage.windowLength)
                        Capsule().fill(Color.primary.opacity(0.55))
                            .frame(width: 2, height: 14)
                            .offset(x: geo.size.width * elapsed - 1)
                            .help("Marker = how far through the \(kind.title.lowercased()) you are, time-wise")
                    }
                }
            }
            .frame(height: 14)

            if let usage {
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 9))
                    Text("resets \(TimeProgress.resetsInString(resetsAt: usage.resetsAt))")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(barColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(barColor.opacity(0.15), in: Capsule())
            } else {
                Text(emptyText).font(.system(size: 10)).foregroundStyle(.tertiary)
            }
        }
    }

    private var barColor: Color {
        switch usage?.utilization ?? 0 {
        case 0.9...: return .red
        case 0.75...: return .orange
        default: return tint
        }
    }
}

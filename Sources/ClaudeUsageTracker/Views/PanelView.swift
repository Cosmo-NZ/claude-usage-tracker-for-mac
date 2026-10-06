import SwiftUI
import AppKit

struct PanelView: View {
    @Bindable var store: UsageStore
    @Bindable var settings: AppSettings
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            UsageBar(kind: .fiveHour, usage: store.snapshot.fiveHour, hasError: subscriptionError, errorMessage: subscriptionErrorMessage, tint: tint)
            UsageBar(kind: .sevenDay, usage: store.snapshot.sevenDay, hasError: subscriptionError, errorMessage: subscriptionErrorMessage, tint: tint)
            if settings.trackOpus {
                UsageBar(kind: .sevenDayOpus, usage: store.snapshot.sevenDayOpus, hasError: subscriptionError, errorMessage: subscriptionErrorMessage, tint: tint, emptyText: "Nothing reported")
            }
            if settings.trackFable {
                UsageBar(kind: .weeklyFable, usage: store.snapshot.weeklyFable, hasError: subscriptionError, errorMessage: subscriptionErrorMessage, tint: tint, emptyText: "Nothing reported")
            }
            if settings.spendEnabled { spendRow }
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
        // Match the Settings window's solid background (adapts to light/dark) rather than a
        // translucent material, so the panel and Settings look consistent.
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        // AppKit's isMovableByWindowBackground no longer reliably drags a borderless,
        // non-activating panel whose content is SwiftUI, so drive the drag explicitly.
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle").font(.system(size: 13)).foregroundStyle(.secondary)
            Text("Claude Usage").font(.system(size: 14, weight: .bold))
            Spacer()
            Text("Always on top").font(.system(size: 10)).foregroundStyle(.secondary)
            Toggle("", isOn: $settings.alwaysOnTop)
                .toggleStyle(.switch).labelsHidden().scaleEffect(0.7)
                .help("Keep the panel above all other windows")
        }
    }

    // MARK: - API spend

    private var spendRow: some View {
        HStack {
            Text("API spend").font(.system(size: 13, weight: .semibold))
            if store.snapshot.sourceErrors[.spend] != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow).font(.system(size: 10))
            }
            Spacer()
            Text(store.snapshot.monthlySpendUSD.map { String(format: "$%.2f this month", $0) } ?? "—")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                if let url = URL(string: "https://status.claude.com/") { NSWorkspace.shared.open(url) }
            } label: {
                HStack(spacing: 6) {
                    Circle().fill(statusColor).frame(width: 8, height: 8)
                    Text(store.snapshot.status.label).font(.system(size: 11))
                }
            }
            .buttonStyle(.plain)
            .help("Open status.claude.com")
            .onHover { $0 ? NSCursor.pointingHand.push() : NSCursor.pop() }

            Spacer()

            if let updated = store.snapshot.lastUpdated {
                Text("Updated \(updatedString(updated))")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }

            iconButton("gearshape", help: "Settings", action: onOpenSettings)
            iconButton("arrow.clockwise", help: "Refresh now") { Task { await store.refresh() } }
            iconButton("power", help: "Quit Claude Usage Tracker") { NSApp.terminate(nil) }
        }
        .foregroundStyle(.secondary)
    }

    private func iconButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName).font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { $0 ? NSCursor.pointingHand.push() : NSCursor.pop() }
    }

    // MARK: - Helpers

    private var subscriptionError: Bool { store.snapshot.sourceErrors[.subscription] != nil }

    private var subscriptionErrorMessage: String? {
        store.snapshot.sourceErrors[.subscription].map { "Couldn't refresh: \($0)" }
    }

    private var tint: Color { settings.barTint.color }

    private var statusColor: Color {
        switch store.snapshot.status.color {
        case .green: return .usageGreen
        case .yellow: return .yellow
        case .red: return .red
        case .gray: return .gray
        }
    }

    private func updatedString(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        return "\(Int(seconds / 3600))h ago"
    }
}

#if DEBUG
private struct PreviewFactory: ClientFactory {
    struct Status: StatusProviding { func fetchStatus() async throws -> ServiceStatus { .operational } }
    struct Sub: SubscriptionProviding {
        func fetchUsage() async throws -> SubscriptionUsage {
            let now = Date()
            return SubscriptionUsage(
                fiveHour: WindowUsage(utilization: 0.34, resetsAt: now.addingTimeInterval(69 * 60), windowLength: 5 * 3600),
                sevenDay: WindowUsage(utilization: 0.41, resetsAt: now.addingTimeInterval((2 * 24 + 5) * 3600), windowLength: 7 * 24 * 3600),
                sevenDayOpus: WindowUsage(utilization: 0.74, resetsAt: now.addingTimeInterval((2 * 24 + 5) * 3600), windowLength: 7 * 24 * 3600),
                weeklyFable: nil)
        }
    }
    @MainActor func makeProviders(settings: AppSettings) -> UsageStore.ClientProviders {
        .init(status: Status(), subscription: Sub(), spend: nil)
    }
}

#Preview {
    let settings = AppSettings.shared
    let store = UsageStore(settings: settings, clientFactory: PreviewFactory())
    return PanelView(store: store, settings: settings, onOpenSettings: {})
        .task { await store.refresh() }
        .padding(40)
}
#endif

import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var store: UsageStore
    var onLaunchAtLoginChanged: (Bool) -> Void
    var onMenuBarChanged: (Bool) -> Void

    enum Section: String, CaseIterable, Identifiable {
        case connect = "Connect", tracking = "Additional Tracking",
             general = "General", appearance = "Appearance", help = "About & Help"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .connect: return "link"
            case .tracking: return "plus.circle"
            case .general: return "gearshape"
            case .appearance: return "paintbrush"
            case .help: return "info.circle"
            }
        }
    }

    @State private var selection: Section = .connect
    @State private var showSignIn = false
    @State private var showHelp = false
    @State private var manualKey = ""
    @State private var manualAdminKey = ""
    @State private var adminKeySaved = KeychainStore.shared.get(.adminKey) != nil
    @State private var sessionConnected = KeychainStore.shared.get(.sessionKey) != nil

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 200)
                .frame(maxHeight: .infinity)
            Divider()
            ScrollView {
                detail.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .tint(accent)
        .frame(width: 640, height: 440)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Section.allCases) { section in
                let selected = selection == section
                Button { selection = section } label: {
                    Label(section.rawValue, systemImage: section.icon)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selected ? accent : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(8)
        .frame(minWidth: 180, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder private var detail: some View {
        switch selection {
        case .connect: connectPane
        case .tracking: trackingPane
        case .general: generalPane
        case .appearance: appearancePane
        case .help: helpPane
        }
    }

    // MARK: - Connect

    private var connectPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            paneHeader("Connect", "Track your Claude.ai usage and sessions")
            card {
                HStack {
                    statusPill(connected: sessionConnected)
                    Spacer()
                }
                if sessionConnected {
                    Button(role: .destructive) {
                        KeychainStore.shared.set(nil, for: .sessionKey)
                        sessionConnected = false
                        Task { await store.refresh() }
                    } label: {
                        Label("Sign out of Claude", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } else {
                    Button { showSignIn = true } label: {
                        Label("Sign in to Claude.ai", systemImage: "globe")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            card {
                Text("Advanced").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                Text("Paste a sessionKey value manually.").font(.caption).foregroundStyle(.secondary)
                HStack {
                    SecureField("sessionKey value", text: $manualKey)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") {
                        guard !manualKey.isEmpty else { return }
                        KeychainStore.shared.set(manualKey, for: .sessionKey)
                        manualKey = ""
                        sessionConnected = true
                        Task { await store.refresh() }
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            VStack(spacing: 0) {
                HStack {
                    Text("Sign in to Claude.ai").font(.headline)
                    Spacer()
                    Button("Cancel") { showSignIn = false }
                }.padding()
                SignInWebView { key in
                    KeychainStore.shared.set(key, for: .sessionKey)
                    sessionConnected = true
                    showSignIn = false
                    Task { await store.refresh() }
                }
            }.frame(width: 520, height: 600)
        }
    }

    // MARK: - Additional Tracking

    private var trackingPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            paneHeader("Additional Tracking", "Track extra usage sources in the panel.")
            card {
                Toggle("Track API spend", isOn: $settings.spendEnabled)
                if settings.spendEnabled {
                    Divider()
                    Text("Admin API key").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    HStack {
                        SecureField("sk-ant-admin…", text: $manualAdminKey)
                            .textFieldStyle(.roundedBorder)
                        Button("Save") {
                            guard !manualAdminKey.isEmpty else { return }
                            KeychainStore.shared.set(manualAdminKey, for: .adminKey)
                            manualAdminKey = ""
                            adminKeySaved = true
                            Task { await store.refresh() }
                        }
                    }
                    if adminKeySaved {
                        Label("Key saved", systemImage: "checkmark.circle.fill").foregroundStyle(accent)
                            .font(.system(size: 12))
                    }
                }
            }
            card {
                Toggle("Track Opus weekly usage", isOn: $settings.trackOpus)
                Text("Adds a Weekly (Opus) row for the separate weekly cap that applies to Opus only.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            card {
                Toggle("Track Fable weekly usage", isOn: $settings.trackFable)
                Text("When on, a Weekly (Fable) row appears in the floating panel.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - General

    private var generalPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            paneHeader("General")
            card {
                Text("Menu bar shows").font(.system(size: 13, weight: .medium))
                Picker("", selection: $settings.menuBarMetric) {
                    ForEach(MenuBarMetric.allCases) { metric in
                        Text(metric.label).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text("Which limit the menu-bar percentage reflects.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            card {
                Text("Refresh interval: \(Int(settings.refreshInterval))s")
                    .font(.system(size: 13, weight: .medium))
                Slider(value: $settings.refreshInterval, in: 10...300, step: 5) { editing in
                    if !editing { store.restartTimer() }
                }
                HStack { Text("10s").font(.caption2); Spacer(); Text("300s").font(.caption2) }
                    .foregroundStyle(.secondary)
            }
            card {
                Toggle("Threshold notifications (75 / 90 / 95%)", isOn: $settings.notificationsEnabled)
                Divider()
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in onLaunchAtLoginChanged(newValue) }
            }
        }
    }

    // MARK: - Appearance

    private var appearancePane: some View {
        VStack(alignment: .leading, spacing: 20) {
            paneHeader("Appearance")
            card {
                Toggle("Always on top", isOn: $settings.alwaysOnTop)
                Text(settings.alwaysOnTop
                     ? "The panel stays visible above other windows."
                     : "Panel is hidden; click the menu bar icon to show/hide it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            card {
                Text("Bar colour").font(.system(size: 13, weight: .medium))
                Picker("", selection: $settings.barTint) {
                    ForEach(BarTint.allCases) { tint in
                        Text(tint.label).tag(tint)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text("Colour of usage bars in the normal range. Amber and red still appear as usage gets high.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            card {
                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
                    .onChange(of: settings.showMenuBarIcon) { _, newValue in onMenuBarChanged(newValue) }
                    .disabled(!settings.alwaysOnTop)
                if !settings.alwaysOnTop {
                    Text("Kept on while “Always on top” is off, so the panel stays reachable.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            card {
                Text("Appearance mode").font(.system(size: 13, weight: .medium))
                Picker("", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            card {
                Text("Panel opacity: \(Int(settings.panelOpacity * 100))%")
                    .font(.system(size: 13, weight: .medium))
                Slider(value: $settings.panelOpacity, in: 0.3...1.0)
                HStack { Text("See-through").font(.caption2); Spacer(); Text("Solid").font(.caption2) }
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - About & Help

    private var helpPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                if let icon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: icon).resizable().frame(width: 52, height: 52)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Claude Usage Tracker").font(.title2.bold())
                    Text("Version \(appVersion)").foregroundStyle(.secondary)
                }
            }
            card {
                Button { showHelp = true } label: {
                    Label("Open Help", systemImage: "book")
                }
                .buttonStyle(.borderedProminent)
                Divider()
                linkRow(icon: "safari", title: "View latest online",
                        url: "https://cosmo-nz.github.io/Floating-Claude-Usage-Tracker/")
            }
            card {
                linkRow(icon: "globe", title: "CramerLabs", url: "https://www.cramerlabs.com")
            }
        }
        .sheet(isPresented: $showHelp) {
            VStack(spacing: 0) {
                HStack {
                    Text("Help").font(.headline)
                    Spacer()
                    Button("Done") { showHelp = false }
                }
                .padding()
                Divider()
                HelpWebView()
            }
            .frame(width: 720, height: 620)
        }
    }

    // MARK: - Building blocks

    private func paneHeader(_ title: String, _ subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.bold())
            if let subtitle {
                Text(subtitle).font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private var accent: Color { settings.barTint.color }

    private func statusPill(connected: Bool) -> some View {
        HStack(spacing: 6) {
            Circle().fill(connected ? accent : .gray).frame(width: 8, height: 8)
            Text(connected ? "Connected" : "Not connected").font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(connected ? accent : Color.secondary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background((connected ? accent : Color.gray).opacity(0.15), in: Capsule())
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private func linkRow(icon: String, title: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).frame(width: 18)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

#if DEBUG
#Preview {
    SettingsView(
        settings: .shared,
        store: UsageStore(settings: .shared),
        onLaunchAtLoginChanged: { _ in },
        onMenuBarChanged: { _ in })
}
#endif

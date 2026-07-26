import Foundation
import Observation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum MenuBarMetric: String, CaseIterable, Identifiable {
    case session, weekly
    var id: String { rawValue }
    var label: String {
        switch self {
        case .session: return "Session"
        case .weekly: return "Weekly"
        }
    }
}

enum BarTint: String, CaseIterable, Identifiable {
    case green, claude, blue
    var id: String { rawValue }
    var label: String {
        switch self {
        case .green: return "Green"
        case .claude: return "Claude"
        case .blue: return "Blue"
        }
    }
}

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings(suiteName: "com.marccramer.ClaudeUsageTracker.settings")

    @ObservationIgnored private let defaults: UserDefaults

    var refreshInterval: Double { didSet { defaults.set(refreshInterval, forKey: "refreshInterval") } }
    var spendEnabled: Bool { didSet { defaults.set(spendEnabled, forKey: "spendEnabled") } }
    var trackFable: Bool { didSet { defaults.set(trackFable, forKey: "trackFable") } }
    var trackOpus: Bool { didSet { defaults.set(trackOpus, forKey: "trackOpus") } }
    var notificationsEnabled: Bool { didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") } }
    var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") } }
    var alwaysOnTop: Bool { didSet { defaults.set(alwaysOnTop, forKey: "alwaysOnTop") } }
    var panelOpacity: Double { didSet { defaults.set(panelOpacity, forKey: "panelOpacity") } }
    var showMenuBarIcon: Bool { didSet { defaults.set(showMenuBarIcon, forKey: "showMenuBarIcon") } }
    var appearance: AppAppearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    var menuBarMetric: MenuBarMetric { didSet { defaults.set(menuBarMetric.rawValue, forKey: "menuBarMetric") } }
    var barTint: BarTint { didSet { defaults.set(barTint.rawValue, forKey: "barTint") } }
    var panelOriginX: Double { didSet { defaults.set(panelOriginX, forKey: "panelOriginX") } }
    var panelOriginY: Double { didSet { defaults.set(panelOriginY, forKey: "panelOriginY") } }

    init(suiteName: String) {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.defaults = defaults
        defaults.register(defaults: [
            "refreshInterval": 30.0,
            "alwaysOnTop": true,
            "panelOpacity": 1.0,
            "notificationsEnabled": true,
            "panelOriginX": -1.0,
            "panelOriginY": -1.0,
        ])
        refreshInterval = defaults.double(forKey: "refreshInterval")
        spendEnabled = defaults.bool(forKey: "spendEnabled")
        trackFable = defaults.bool(forKey: "trackFable")
        trackOpus = defaults.bool(forKey: "trackOpus")
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        alwaysOnTop = defaults.bool(forKey: "alwaysOnTop")
        panelOpacity = defaults.double(forKey: "panelOpacity")
        showMenuBarIcon = defaults.bool(forKey: "showMenuBarIcon")
        appearance = AppAppearance(rawValue: defaults.string(forKey: "appearance") ?? "system") ?? .system
        menuBarMetric = MenuBarMetric(rawValue: defaults.string(forKey: "menuBarMetric") ?? "session") ?? .session
        barTint = BarTint(rawValue: defaults.string(forKey: "barTint") ?? "green") ?? .green
        panelOriginX = defaults.double(forKey: "panelOriginX")
        panelOriginY = defaults.double(forKey: "panelOriginY")
    }
}

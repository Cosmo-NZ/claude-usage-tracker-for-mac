import AppKit

// The app launches on the main thread, so it is safe to assume main-actor
// isolation here in order to construct the main-actor-isolated AppDelegate.
MainActor.assumeIsolated {
    // Show `.help(...)` tooltips faster than AppKit's default initial delay (milliseconds).
    UserDefaults.standard.register(defaults: ["NSInitialToolTipDelay": 500])

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}

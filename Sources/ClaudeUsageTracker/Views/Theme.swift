import SwiftUI

extension Color {
    /// A fixed green matching macOS system green's light-appearance value (#34C759).
    /// Used in both light and dark mode so it doesn't look fluorescent in the dark.
    static let usageGreen = Color(red: 52.0 / 255.0, green: 199.0 / 255.0, blue: 89.0 / 255.0)

    /// Claude accent (#c15f3c).
    static let claudeAccent = Color(red: 0xC1 / 255.0, green: 0x5F / 255.0, blue: 0x3C / 255.0)

    /// Blue (#1591EA).
    static let usageBlue = Color(red: 0x15 / 255.0, green: 0x91 / 255.0, blue: 0xEA / 255.0)
}

extension BarTint {
    /// The bar colour used in the normal (non-warning) usage range.
    var color: Color {
        switch self {
        case .green: return .usageGreen
        case .claude: return .claudeAccent
        case .blue: return .usageBlue
        }
    }
}

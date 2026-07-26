import Foundation

/// Loads JSON fixtures bundled with the unit-test target.
///
/// Xcode may copy the `Fixtures` resources either flattened into the bundle
/// root or preserving the folder, so we look in both places.
enum FixtureLoader {
    private final class Token {}

    static func data(_ name: String) throws -> Data {
        let bundle = Bundle(for: Token.self)
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
            ?? bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }
}

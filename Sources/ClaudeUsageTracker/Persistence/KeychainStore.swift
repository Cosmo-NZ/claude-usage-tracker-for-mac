import Foundation
import Security

struct KeychainStore {
    enum Key: String { case sessionKey, adminKey }

    /// The production store used by the app. Tests construct their own instance with a
    /// throwaway service name so they never touch real credentials.
    static let shared = KeychainStore(service: "com.marccramer.ClaudeUsageTracker")

    let service: String

    /// Keychain syscalls run on a private serial queue so `SecItem*` never executes on
    /// the main thread (which trips the Thread Performance Checker). The API stays
    /// synchronous — the calls are on tiny tokens, so the wait is negligible. We use
    /// `async` + a semaphore (not `sync`, which GCD may run on the calling thread) to
    /// guarantee the work runs off the caller's thread.
    private static let queue = DispatchQueue(label: "com.marccramer.ClaudeUsageTracker.keychain")

    private static func offMain<T: Sendable>(_ work: @escaping @Sendable () -> T) -> T {
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result: T!
        queue.async {
            result = work()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    func set(_ value: String?, for key: Key) {
        let service = self.service
        Self.offMain {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key.rawValue,
            ]
            SecItemDelete(query as CFDictionary)
            guard let value, let data = value.data(using: .utf8) else { return }
            var add = query
            add[kSecValueData as String] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    func get(_ key: Key) -> String? {
        let service = self.service
        return Self.offMain {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key.rawValue,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            var item: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
                  let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }
}

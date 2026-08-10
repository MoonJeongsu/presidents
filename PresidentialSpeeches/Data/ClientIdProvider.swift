import Foundation

final class ClientIdProvider {
    private let defaults: UserDefaults
    private let key = "translation_client_id"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getClientId() -> String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        defaults.set(created, forKey: key)
        return created
    }
}

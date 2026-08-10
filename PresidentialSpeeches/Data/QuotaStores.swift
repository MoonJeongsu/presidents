import Foundation

final class TranslationQuotaStore {
    private let defaults: UserDefaults
    private let usedKey = "translation_quota_used"
    private let limitKey = "translation_quota_limit"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveQuota(used: Int, limit: Int) {
        defaults.set(used, forKey: usedKey)
        defaults.set(limit, forKey: limitKey)
    }

    func getQuotaUsed() -> Int {
        defaults.integer(forKey: usedKey)
    }

    func getQuotaLimit() -> Int {
        let stored = defaults.integer(forKey: limitKey)
        return stored > 0 ? stored : AppConfig.defaultQuotaLimit
    }
}

final class TtsQuotaStore {
    private let defaults: UserDefaults
    private let usedKey = "tts_quota_used"
    private let limitKey = "tts_quota_limit"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveQuota(used: Int, limit: Int) {
        defaults.set(used, forKey: usedKey)
        defaults.set(limit, forKey: limitKey)
    }

    func getQuotaUsed() -> Int {
        defaults.integer(forKey: usedKey)
    }

    func getQuotaLimit() -> Int {
        let stored = defaults.integer(forKey: limitKey)
        return stored > 0 ? stored : AppConfig.defaultQuotaLimit
    }
}

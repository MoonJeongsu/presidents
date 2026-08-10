import Foundation

struct TranslationCacheEntry: Codable {
    let sourceHash: String
    let sourceText: String
    let translatedText: String
    let createdAt: TimeInterval
}

final class TranslationCacheStore {
    private let fileURL: URL
    private var entries: [String: TranslationCacheEntry] = [:]
    private let queue = DispatchQueue(label: "translation-cache-store")

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = directory.appendingPathComponent("PresidentialSpeeches", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        fileURL = appDirectory.appendingPathComponent("translation_cache.json")
        loadFromDisk()
    }

    func getByHash(_ sourceHash: String) -> TranslationCacheEntry? {
        queue.sync { entries[sourceHash] }
    }

    func insert(_ entry: TranslationCacheEntry) {
        queue.sync {
            entries[entry.sourceHash] = entry
            saveToDisk()
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let decoded = try? JSONDecoder().decode([TranslationCacheEntry].self, from: data) else { return }
        entries = Dictionary(uniqueKeysWithValues: decoded.map { ($0.sourceHash, $0) })
    }

    private func saveToDisk() {
        let values = Array(entries.values)
        guard let data = try? JSONEncoder().encode(values) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

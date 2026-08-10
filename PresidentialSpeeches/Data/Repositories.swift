import Foundation

enum TranslationResult {
    case success(translatedText: String, fromLocalCache: Bool, quotaUsed: Int, quotaLimit: Int)
    case quotaExceeded(quotaUsed: Int, quotaLimit: Int)
    case error(message: String)
}

final class TranslationRepository {
    private let cacheStore: TranslationCacheStore
    private let api: CloudTranslationApi
    private let quotaStore: TranslationQuotaStore
    private let clientIdProvider: ClientIdProvider

    init(
        cacheStore: TranslationCacheStore = TranslationCacheStore(),
        api: CloudTranslationApi = CloudTranslationApi(),
        quotaStore: TranslationQuotaStore = TranslationQuotaStore(),
        clientIdProvider: ClientIdProvider = ClientIdProvider()
    ) {
        self.cacheStore = cacheStore
        self.api = api
        self.quotaStore = quotaStore
        self.clientIdProvider = clientIdProvider
    }

    func translate(_ text: String) async -> TranslationResult {
        let sourceHash = TextHash.sha256(text)

        if let cached = cacheStore.getByHash(sourceHash) {
            return .success(
                translatedText: cached.translatedText,
                fromLocalCache: true,
                quotaUsed: quotaStore.getQuotaUsed(),
                quotaLimit: quotaStore.getQuotaLimit()
            )
        }

        switch await api.translate(text: text, clientId: clientIdProvider.getClientId()) {
        case let .success(translatedText, _, quotaUsed, quotaLimit):
            cacheStore.insert(
                TranslationCacheEntry(
                    sourceHash: sourceHash,
                    sourceText: text,
                    translatedText: translatedText,
                    createdAt: Date().timeIntervalSince1970
                )
            )
            quotaStore.saveQuota(used: quotaUsed, limit: quotaLimit)
            return .success(
                translatedText: translatedText,
                fromLocalCache: false,
                quotaUsed: quotaUsed,
                quotaLimit: quotaLimit
            )

        case let .quotaExceeded(quotaUsed, quotaLimit):
            quotaStore.saveQuota(used: quotaUsed, limit: quotaLimit)
            return .quotaExceeded(quotaUsed: quotaUsed, quotaLimit: quotaLimit)

        case let .error(message):
            return .error(message: message)
        }
    }

    func getCachedQuotaUsed() -> Int {
        quotaStore.getQuotaUsed()
    }

    func getCachedQuotaLimit() -> Int {
        quotaStore.getQuotaLimit()
    }
}

enum TtsResult {
    case success(audioFile: URL, fromLocalCache: Bool, quotaUsed: Int, quotaLimit: Int)
    case quotaExceeded(quotaUsed: Int, quotaLimit: Int)
    case error(message: String)
}

final class TtsRepository {
    private let api: CloudTtsApi
    private let quotaStore: TtsQuotaStore
    private let clientIdProvider: ClientIdProvider
    private let cacheDirectory: URL
    private let session: URLSession

    init(
        api: CloudTtsApi = CloudTtsApi(),
        quotaStore: TtsQuotaStore = TtsQuotaStore(),
        clientIdProvider: ClientIdProvider = ClientIdProvider(),
        session: URLSession = .shared
    ) {
        self.api = api
        self.quotaStore = quotaStore
        self.clientIdProvider = clientIdProvider
        self.session = session

        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = base.appendingPathComponent("tts_audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func synthesize(_ text: String) async -> TtsResult {
        let sourceHash = TextHash.sha256(text)
        let localFile = cacheDirectory.appendingPathComponent("\(sourceHash).mp3")

        if FileManager.default.fileExists(atPath: localFile.path),
           let attributes = try? FileManager.default.attributesOfItem(atPath: localFile.path),
           let size = attributes[.size] as? NSNumber,
           size.intValue > 0 {
            return .success(
                audioFile: localFile,
                fromLocalCache: true,
                quotaUsed: quotaStore.getQuotaUsed(),
                quotaLimit: quotaStore.getQuotaLimit()
            )
        }

        switch await api.synthesize(text: text, clientId: clientIdProvider.getClientId()) {
        case let .success(audioURL, _, quotaUsed, quotaLimit):
            do {
                try await downloadAudio(from: audioURL, to: localFile)
                quotaStore.saveQuota(used: quotaUsed, limit: quotaLimit)
                return .success(
                    audioFile: localFile,
                    fromLocalCache: false,
                    quotaUsed: quotaUsed,
                    quotaLimit: quotaLimit
                )
            } catch {
                return .error(message: error.localizedDescription)
            }

        case let .quotaExceeded(quotaUsed, quotaLimit):
            quotaStore.saveQuota(used: quotaUsed, limit: quotaLimit)
            return .quotaExceeded(quotaUsed: quotaUsed, quotaLimit: quotaLimit)

        case let .error(message):
            return .error(message: message)
        }
    }

    func getCachedQuotaUsed() -> Int {
        quotaStore.getQuotaUsed()
    }

    func getCachedQuotaLimit() -> Int {
        quotaStore.getQuotaLimit()
    }

    private func downloadAudio(from urlString: String, to destination: URL) async throws {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "TtsRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio download failed."])
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
            throw NSError(domain: "TtsRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Audio download failed."])
        }
        try data.write(to: destination, options: [.atomic])
    }
}

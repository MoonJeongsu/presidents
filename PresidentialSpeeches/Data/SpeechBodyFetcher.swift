import Foundation

final class SpeechBodyFetcher {
    private let bucket: String
    private let session: URLSession
    private var memoryCache: [String: String] = [:]
    private let cacheLock = NSLock()

    init(
        bucket: String = AppConfig.firebaseStorageBucket,
        session: URLSession = .shared
    ) {
        self.bucket = bucket
        self.session = session
    }

    func fetchBody(speechId: String) async throws -> String {
        cacheLock.lock()
        if let cached = memoryCache[speechId] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        guard NetworkUtils.isConnected else {
            throw SpeechBodyError.networkUnavailable
        }

        guard !bucket.isEmpty else {
            throw SpeechBodyError.bucketNotConfigured
        }

        let objectPath = "speeches/\(speechId).txt"
        var allowed = CharacterSet.urlPathAllowed
        allowed.insert(charactersIn: "/")
        let encodedPath = objectPath.addingPercentEncoding(withAllowedCharacters: allowed) ?? objectPath
        let urlString = "https://firebasestorage.googleapis.com/v0/b/\(bucket)/o/\(encodedPath)?alt=media"
        guard let url = URL(string: urlString) else {
            throw SpeechBodyError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw SpeechBodyError.downloadFailed(statusCode: nil)
        }
        guard http.statusCode == 200 else {
            throw SpeechBodyError.downloadFailed(statusCode: http.statusCode)
        }
        guard let body = String(data: data, encoding: .utf8), !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeechBodyError.emptyBody
        }

        cacheLock.lock()
        memoryCache[speechId] = body
        cacheLock.unlock()
        return body
    }
}

enum SpeechBodyError: LocalizedError {
    case networkUnavailable
    case bucketNotConfigured
    case invalidURL
    case downloadFailed(statusCode: Int?)
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "This app requires an internet connection. Please connect to the network and try again."
        case .bucketNotConfigured:
            return "Firebase Storage bucket is not configured."
        case .invalidURL:
            return "Could not download the speech. Check your connection and try again."
        case .downloadFailed:
            return "Could not download the speech. Check your connection and try again."
        case .emptyBody:
            return "Speech text is not available."
        }
    }
}

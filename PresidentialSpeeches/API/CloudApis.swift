import Foundation

enum TranslationApiResult {
    case success(translatedText: String, fromCache: Bool, quotaUsed: Int, quotaLimit: Int)
    case quotaExceeded(quotaUsed: Int, quotaLimit: Int)
    case error(message: String)
}

final class CloudTranslationApi {
    private let translateURL: URL
    private let session: URLSession

    init(
        translateURL: URL = AppConfig.translateFunctionURL,
        session: URLSession = .shared
    ) {
        self.translateURL = translateURL
        self.session = session
    }

    func translate(text: String, clientId: String) async -> TranslationApiResult {
        let payload: [String: String] = [
            "text": text,
            "clientId": clientId,
        ]

        var request = URLRequest(url: translateURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .error(message: "Translation failed.")
            }

            if http.statusCode == 429 {
                let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
                return .quotaExceeded(
                    quotaUsed: json["quotaUsed"] as? Int ?? AppConfig.defaultQuotaLimit,
                    quotaLimit: json["quotaLimit"] as? Int ?? AppConfig.defaultQuotaLimit
                )
            }

            guard http.statusCode == 200 else {
                let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
                let message = json["error"] as? String ?? "Translation failed."
                return .error(message: message)
            }

            let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            guard let translatedText = json["translatedText"] as? String else {
                return .error(message: "Translation failed.")
            }

            return .success(
                translatedText: translatedText,
                fromCache: json["fromCache"] as? Bool ?? false,
                quotaUsed: json["quotaUsed"] as? Int ?? 0,
                quotaLimit: json["quotaLimit"] as? Int ?? AppConfig.defaultQuotaLimit
            )
        } catch {
            return .error(message: error.localizedDescription)
        }
    }
}

enum TtsApiResult {
    case success(audioURL: String, fromCache: Bool, quotaUsed: Int, quotaLimit: Int)
    case quotaExceeded(quotaUsed: Int, quotaLimit: Int)
    case error(message: String)
}

final class CloudTtsApi {
    private let synthesizeURL: URL
    private let session: URLSession

    init(
        synthesizeURL: URL = AppConfig.synthesizeFunctionURL,
        session: URLSession = .shared
    ) {
        self.synthesizeURL = synthesizeURL
        self.session = session
    }

    func synthesize(text: String, clientId: String) async -> TtsApiResult {
        let payload: [String: String] = [
            "text": text,
            "clientId": clientId,
        ]

        var request = URLRequest(url: synthesizeURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .error(message: "Speech synthesis failed.")
            }

            if http.statusCode == 429 {
                let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
                return .quotaExceeded(
                    quotaUsed: json["quotaUsed"] as? Int ?? AppConfig.defaultQuotaLimit,
                    quotaLimit: json["quotaLimit"] as? Int ?? AppConfig.defaultQuotaLimit
                )
            }

            guard http.statusCode == 200 else {
                let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
                let message = json["error"] as? String ?? "Speech synthesis failed."
                return .error(message: message)
            }

            let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            guard let audioURL = json["audioUrl"] as? String else {
                return .error(message: "Speech synthesis failed.")
            }

            return .success(
                audioURL: audioURL,
                fromCache: json["fromCache"] as? Bool ?? false,
                quotaUsed: json["quotaUsed"] as? Int ?? 0,
                quotaLimit: json["quotaLimit"] as? Int ?? AppConfig.defaultQuotaLimit
            )
        } catch {
            return .error(message: error.localizedDescription)
        }
    }
}

import CryptoKit
import Foundation

enum TextHash {
    static func sha256(_ text: String) -> String {
        let data = Data(text.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

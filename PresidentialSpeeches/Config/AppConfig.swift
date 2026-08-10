import Foundation

enum AppConfig {
    static let showAds = false

    static let translateFunctionURL = URL(string: "https://us-central1-presidential-speeches-a9f00.cloudfunctions.net/translateSentence")!
    static let synthesizeFunctionURL = URL(string: "https://us-central1-presidential-speeches-a9f00.cloudfunctions.net/synthesizeSentence")!
    static let firebaseStorageBucket = "presidential-speeches-a9f00.firebasestorage.app"

    static let defaultQuotaLimit = 40
}

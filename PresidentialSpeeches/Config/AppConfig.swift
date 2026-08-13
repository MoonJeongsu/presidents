import Foundation

enum AppConfig {
    /// Set to `true` only after iOS AdMob units are configured in Xcode.
    static let showAds = false

    static let translateFunctionURL = URL(string: "https://us-central1-presidential-speeches-a9f00.cloudfunctions.net/translateSentence")!
    static let synthesizeFunctionURL = URL(string: "https://us-central1-presidential-speeches-a9f00.cloudfunctions.net/synthesizeSentence")!
    static let firebaseStorageBucket = "presidential-speeches-a9f00.firebasestorage.app"

    static let defaultQuotaLimit = 40
}

enum AppAds {
    static var isEnabled: Bool { AppConfig.showAds }
}

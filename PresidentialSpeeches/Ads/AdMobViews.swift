import SwiftUI

/// AdMob UI entry point. Returns empty content while `AppConfig.showAds` is false.
struct AdMobBannerView: View {
    var body: some View {
        if AppAds.isEnabled {
            // Wire Google Mobile Ads banner here when enabling ads.
            EmptyView()
        } else {
            EmptyView()
        }
    }
}

enum AdMobInterstitialManager {
    static func showThenNavigate(onNavigate: @escaping () -> Void) {
        onNavigate()
    }
}

enum AdMobRewardedManager {
    static func showForReward(onRewardEarned: @escaping () -> Void, onFinished: @escaping () -> Void) {
        onFinished()
    }
}

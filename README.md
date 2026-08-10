# iOS App — US Presidential Speeches

SwiftUI iOS client for the same Firebase backend used by the Android app.

## Features

- President list and speech list (bundled JSON)
- Speech bodies downloaded from Firebase Storage (online required)
- Sentence tap → Korean translation via Cloud Functions
- Speaker icon → English Neural TTS via Cloud Functions
- Daily quota: 40 translations / 40 TTS clips (same backend as Android)
- **AdMob disabled** (`AppConfig.showAds = false`)

## Open in Xcode

1. Copy/sync this folder to a Mac (or use the repo as-is on Mac).
2. Open `PresidentialSpeeches/ios/PresidentialSpeeches.xcodeproj`.
3. Set **Signing & Capabilities → Team** to your Apple Developer team.
4. Run on simulator or device (network required).

## Sync JSON assets from Android

When Android assets change, refresh iOS copies:

```bash
cp ../app/src/main/assets/presidents.json PresidentialSpeeches/Resources/
cp ../app/src/main/assets/speeches_index.json PresidentialSpeeches/Resources/
```

## Configuration

Edit `PresidentialSpeeches/Config/AppConfig.swift`:

- Cloud Function URLs
- Firebase Storage bucket
- `showAds` (future AdMob toggle)

## Bundle ID

Default: `com.uspresident.speeches.ios`

Change in Xcode target settings before App Store submission.

## App Store checklist

- Add App Icon images to `Assets.xcassets/AppIcon.appiconset`
- Set Development Team in Xcode
- Privacy policy URL (translation/TTS data sent to Google Cloud)
- App Privacy labels in App Store Connect

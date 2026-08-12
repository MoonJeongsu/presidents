#!/bin/bash
# App Store Connect 아카이브 + 업로드
#
#   ./scripts/archive-and-upload.sh          # 아카이브 + IPA export 까지만
#   ./scripts/archive-and-upload.sh --upload # App Store Connect 업로드까지
#
# 인증: jeongsu moon 팀(2YRVXN68GB) 전용 ASC API 키 DQL5S465VF 사용.
set -euo pipefail

cd "$(dirname "$0")/.."

# Xcode.app이 xcode-select 기본값이 아닐 수 있으므로 명시
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

SCHEME="PresidentialSpeeches"
PROJECT="PresidentialSpeeches.xcodeproj"
OUT="build-archive"
ARCHIVE="$OUT/$SCHEME.xcarchive"

AUTH_ARGS=(
  -authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_DQL5S465VF.p8"
  -authenticationKeyID DQL5S465VF
  -authenticationKeyIssuerID a903f345-abb0-48b0-b2ae-594f0f7263dd
)

echo "==> 아카이브"
rm -rf "$ARCHIVE"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates "${AUTH_ARGS[@]}"

echo "==> IPA export"
rm -rf "$OUT/export"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath "$OUT/export" \
  -allowProvisioningUpdates "${AUTH_ARGS[@]}"

IPA=$(find "$OUT/export" -name "*.ipa" -maxdepth 1 | head -1)
if [ -z "$IPA" ]; then
  echo "IPA를 찾지 못했습니다." >&2
  exit 1
fi
echo "==> IPA: $IPA"

if [ "${1:-}" != "--upload" ]; then
  echo
  echo "업로드하려면: $0 --upload"
  exit 0
fi

echo "==> App Store Connect 업로드"
rm -rf "$OUT/upload"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist ExportOptions-upload.plist \
  -exportPath "$OUT/upload" \
  -allowProvisioningUpdates "${AUTH_ARGS[@]}"

echo "==> 완료. App Store Connect에서 처리(수 분) 후 TestFlight에 나타납니다."
echo "    빌드를 다시 올리려면 CURRENT_PROJECT_VERSION을 올리세요."

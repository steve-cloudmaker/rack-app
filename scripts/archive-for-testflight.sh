#!/usr/bin/env bash
# Build an App Store–signed IPA for TestFlight upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Cedar"
ARCHIVE_PATH="$ROOT/build/Cedar.xcarchive"
EXPORT_PATH="$ROOT/build/export"
EXPORT_OPTIONS="$ROOT/scripts/ExportOptions-app-store.plist"

cd "$ROOT"

if [[ ! -d "$ROOT/Cedar.xcodeproj" ]]; then
  echo "Generating Xcode project…"
  xcodegen generate
fi

echo "Archiving $SCHEME (Release, iOS)…"
xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo "Exporting IPA for App Store Connect…"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

echo ""
echo "Done. Upload this IPA to TestFlight:"
echo "  $EXPORT_PATH/Cedar.ipa"
echo ""
echo "Upload options:"
echo "  • Transporter app (drag Cedar.ipa)"
echo "  • Xcode → Organizer → Distribute App"
echo "  • xcrun altool --upload-app -f \"$EXPORT_PATH/Cedar.ipa\" --type ios --apiKey KEY --apiIssuer ISSUER"

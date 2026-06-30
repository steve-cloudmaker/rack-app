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
  -allowProvisioningUpdates \
  archive

echo "Exporting IPA for App Store Connect…"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates

echo ""
echo "Done. IPA ready at:"
echo "  $EXPORT_PATH/Cedar.ipa"
echo ""
echo "Upload to TestFlight:"
echo "  ./scripts/upload-to-testflight.sh"
echo ""
echo "Requires App Store Connect API key env vars (see scripts/upload-to-testflight.sh)."

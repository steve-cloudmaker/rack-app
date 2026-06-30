#!/usr/bin/env bash
# Upload an App Store IPA to TestFlight via App Store Connect API.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA="${1:-$ROOT/build/export/Cedar.ipa}"

if [[ ! -f "$IPA" ]]; then
  echo "IPA not found: $IPA"
  echo "Run ./scripts/archive-for-testflight.sh first."
  exit 1
fi

# App Store Connect API key (create at https://appstoreconnect.apple.com/access/integrations/api)
: "${ASC_API_KEY_ID:?Set ASC_API_KEY_ID (e.g. export ASC_API_KEY_ID=XXXXXXXXXX)}"
: "${ASC_API_ISSUER_ID:?Set ASC_API_ISSUER_ID (e.g. export ASC_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)}"

if [[ -n "${ASC_API_KEY_PATH:-}" ]]; then
  KEY_PATH="$ASC_API_KEY_PATH"
elif [[ -f "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_API_KEY_ID}.p8" ]]; then
  KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_API_KEY_ID}.p8"
elif [[ -f "$HOME/.private_keys/AuthKey_${ASC_API_KEY_ID}.p8" ]]; then
  KEY_PATH="$HOME/.private_keys/AuthKey_${ASC_API_KEY_ID}.p8"
else
  echo "API key file not found. Set ASC_API_KEY_PATH or place AuthKey_${ASC_API_KEY_ID}.p8 in:"
  echo "  ~/.appstoreconnect/private_keys/"
  exit 1
fi

echo "Uploading $(basename "$IPA") to App Store Connect…"
xcrun altool --upload-app \
  -f "$IPA" \
  --type ios \
  --apiKey "$ASC_API_KEY_ID" \
  --apiIssuer "$ASC_API_ISSUER_ID" \
  --apiKeyPath "$KEY_PATH"

echo ""
echo "Upload submitted. Processing usually takes 5–15 minutes in App Store Connect → TestFlight."

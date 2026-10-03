# Start here

This is **Cedar Closet Manager** — a personal clothing inventory app for
iPhone, iPad, and Mac Catalyst (SwiftUI + Core Data + CloudKit).

Local checkout is typically `~/projects/cedar`. GitHub remote:
[`steve-cloudmaker/rack-app`](https://github.com/steve-cloudmaker/rack-app)
(historical repo name; product and Xcode target are **Cedar**).

## Where things live

| Doc | Read it for |
|---|---|
| [`README.md`](../README.md) | Features, setup, TestFlight CLI, project map |
| [`ARCHITECTURE.md`](../ARCHITECTURE.md) | Data model, CloudKit sync/sharing, view layer, release pipeline |
| [`Common/AI_ONBOARDING.md`](AI_ONBOARDING.md) | Context for an AI assistant picking this up cold |
| `project.yml` | XcodeGen spec — source of truth for team ID, Catalyst, entitlements paths |
| `Rack/` | All app source (historical folder name; do not rename casually) |
| `scripts/archive-for-testflight.sh` | Archive + export App Store IPA |
| `scripts/upload-to-testflight.sh` | Upload IPA via App Store Connect API key |
| `Rack/Info.plist` | Marketing version + build number |

## If you're setting up a machine to build

1. [`README.md`](../README.md) → Setup — `xcodegen generate`, open `Cedar.xcodeproj`
2. Confirm Development Team in `project.yml` (`J7MM7A8SK8`) — do not rely on Xcode-only Signing edits; they are overwritten on regenerate
3. Build and run from Xcode, or use a simulator destination with `xcodebuild`

## If you're shipping a TestFlight build

1. If you added Core Data / CloudKit fields since the last Production schema
   deploy: initialize **Development** schema on a **physical device**
   (Debug → Settings → Developer), then **Deploy Schema Changes** to
   Production in CloudKit Console — see README / `AI_ONBOARDING.md`
2. Bump `CFBundleVersion` in `Rack/Info.plist` (App Store Connect rejects reuse)
3. `./scripts/archive-for-testflight.sh`
4. Ensure `ASC_API_KEY_ID` / `ASC_API_ISSUER_ID` are set and the `.p8` is in `~/.appstoreconnect/private_keys/`
5. `./scripts/upload-to-testflight.sh`
6. Wait 5–15 minutes in App Store Connect → TestFlight

Details and troubleshooting (PLA / ASC agreements, distribution certs,
CloudKit schema) are in the README and [`AI_ONBOARDING.md`](AI_ONBOARDING.md).

## If you're an AI assistant

Read [`Common/AI_ONBOARDING.md`](AI_ONBOARDING.md) before changing code or
running release scripts — it covers naming traps, CloudKit constraints, and
gotchas already diagnosed so you do not rediscover them.

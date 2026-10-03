# Cedar Closet Manager

A personal clothing inventory app for iPhone, iPad, and Mac Catalyst, built with SwiftUI and Core Data.

Cedar gives you a complete view of everything in your wardrobe — including kids clothes that have been outgrown — and helps you track what to keep, donate, or list on Poshmark.

**New here?** Start with [Common/START_HERE.md](Common/START_HERE.md). AI assistants should also read [Common/AI_ONBOARDING.md](Common/AI_ONBOARDING.md).

## Features

- **Full inventory management** — add clothing items with photos (up to 5), brand, size, shoe size, color, condition, and category
- **Camera & photo library** — take new photos or pick from your library directly in the item form
- **Two-path status workflow** — Keep → For Sale → Listed → Sold (with sale date), or Keep → For Donation → Donated (with donated date)
- **Donation value tracking** — record fair market value on donated items (`donationValue`, separate from listing price) for tax deduction purposes
- **Smart size picker** — baby (months), toddler (T-sizes), kids numeric, letter sizes, and shoe sizes, filtered by age group
- **People & locations** — assign items to family members and track physical storage locations (rack/row)
- **Poshmark tracking** — record listing price and sale price per item
- **Advanced filtering** — filter inventory by status, owner, location, and age group
- **AI-powered descriptions** — generate item descriptions from photos using Claude (bring your own API key)
- **AI price estimation** — get resale price suggestions via Claude
- **iCloud sync** — keep inventory in sync across all your iPhone and iPad devices
- **Family sharing** — share your closet with family members via CloudKit (Settings → Share Closet)
- **Import & export** — CSV import/export (flat rows) and a full JSON backup of people, locations, and items (Settings → Data; photos not included)
- **Sync status** — Settings → iCloud Sync shows iCloud account status and the latest CloudKit import/export activity
- **Undo support** — Core Data undo manager is wired to the system undo manager (shake-to-undo on device)
- **MacKinnon Hunting tartan** — splash screen and subtle app background

## Tech Stack

- **SwiftUI** — UI framework (iOS 17+)
- **Core Data + CloudKit** — persistence and iCloud sync via `NSPersistentCloudKitContainer`
- **PhotosUI** — photo library picker
- **UIImagePickerController** — camera capture
- **Anthropic Claude API** — AI features (`claude-haiku-4-5-20251001`)

## Requirements

- iOS 17.0+
- iPadOS 17.0+
- macOS 14.0+ (Mac Catalyst)
- Xcode 15+
- Apple Developer Program membership (for iCloud sync and sharing)

## Setup

1. Clone the repository
2. Run `xcodegen generate` to create `Cedar.xcodeproj`
3. Open `Cedar.xcodeproj` in Xcode
4. Signing uses Automatic style with Development Team `J7MM7A8SK8` (set in `project.yml`). To build under a different team, change `DEVELOPMENT_TEAM` there and re-run `xcodegen generate` — edits made only in Xcode's **Signing & Capabilities** are overwritten on the next generate.
5. Build and run (`Cmd+R`)

### Mac Catalyst (App Store / TestFlight)

The app supports Mac Catalyst (`SUPPORTS_MACCATALYST: YES`). Mac uploads require:

- `LSApplicationCategoryType` in `Info.plist` (lifestyle / wardrobe)
- App Sandbox entitlements in `Rack/Cedar-Mac.entitlements` (used only for the Mac Catalyst build)

To ship **iPhone and iPad only** and skip Mac validation, set `SUPPORTS_MACCATALYST: NO` in `project.yml` and run `xcodegen generate`.

### TestFlight / App Store export compliance

`Rack/Info.plist` sets `ITSAppUsesNonExemptEncryption` to `false`. Cedar only uses exempt encryption (HTTPS for the Anthropic API, standard CloudKit/iOS APIs). This avoids answering the export compliance questionnaire on every upload.

### TestFlight from the command line

The full archive → export → upload flow runs from the terminal via two scripts in `scripts/`.

**1. Archive and export the IPA**

```bash
./scripts/archive-for-testflight.sh
```

- Runs `xcodegen generate` first if `Cedar.xcodeproj` is missing
- Archives the `Cedar` scheme (Release, `generic/platform=iOS`) to `build/Cedar.xcarchive`
- Exports with `scripts/ExportOptions-app-store.plist` (`app-store-connect`, automatic signing, team `J7MM7A8SK8`, symbols uploaded)
- Passes `-allowProvisioningUpdates` so Xcode can create or refresh the distribution certificate and provisioning profile without opening the IDE
- Writes the IPA to `build/export/Cedar.ipa`

**2. Upload to TestFlight**

```bash
export ASC_API_KEY_ID=XXXXXXXXXX
export ASC_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
./scripts/upload-to-testflight.sh            # or pass a path to a different .ipa
```

Uploads with `xcrun altool` using an App Store Connect API key (create one under **App Store Connect → Users and Access → Integrations → App Store Connect API**). The `.p8` key file is located from, in order:

1. `ASC_API_KEY_PATH` (explicit path)
2. `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`
3. `~/.private_keys/AuthKey_<KEY_ID>.p8`

Never commit the `.p8` file. Processing usually takes 5–15 minutes before the build appears under **TestFlight** in App Store Connect.

**Version and build number**

`CFBundleShortVersionString` (marketing version) and `CFBundleVersion` (build number) are set directly in `Rack/Info.plist`. Current shipping line: **1.1** (build **4**). App Store Connect rejects an upload whose build number was already used for that version, so bump `CFBundleVersion` before each new upload.

Transporter or Xcode → Organizer → Distribute App still work as manual alternatives for uploading `build/export/Cedar.ipa`.

**CLI troubleshooting**

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| `PLA Update available` / no iOS Distribution certificate on export | Developer Program License Agreement not accepted | Accept at [developer.apple.com/account](https://developer.apple.com/account), retry archive |
| `REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED` / `altool` cannot map bundle ID | App Store Connect agreements pending | Accept agreements under [Agreements, Tax, and Banking](https://appstoreconnect.apple.com/agreements). Banking “pending processing” does **not** block TestFlight once agreements are Active |
| Empty CloudKit container list in Xcode | Same as PLA / portal refresh | Accept agreements, reopen Signing & Capabilities — do not recreate the container unless it is actually gone |

### iCloud Sync

CloudKit is enabled by default via `iCloud.com.stevedaurora.cedar`. You'll need:

- A paid Apple Developer Program membership
- The App ID `com.stevedaurora.cedar` registered in the Developer portal with CloudKit enabled
- The iCloud container `iCloud.com.stevedaurora.cedar` created and linked

The app uses two Core Data store configurations:

- **Default** — your personal closet data (same CloudKit zone SwiftData used)
- **Shared** — data received from CloudKit share invitations

**Debug vs TestFlight databases:** Xcode Debug builds sync to CloudKit
**Development**; TestFlight / App Store builds use **Production**. They do not
share data. After adding Core Data attributes (for example `saleDate` →
CloudKit field `CD_saleDate`), you must update the Development schema and
**deploy it to Production** or TestFlight exports fail.

#### Updating the CloudKit schema after a model change

1. Run a **Debug** build on a **physical device** signed into iCloud (simulators are unreliable for schema init).
2. **Settings → Developer → Initialize CloudKit Development Schema** (Debug builds only).
3. In [CloudKit Console](https://icloud.developer.apple.com/dashboard) → `iCloud.com.stevedaurora.cedar` → Development → Schema, confirm new fields (e.g. `CD_saleDate` on `CD_ClothingItem`).
4. **Deploy Schema Changes…** to Production and confirm the fields appear there.
5. Relaunch the TestFlight build and check **Settings → iCloud Sync**.

### Troubleshooting sync on a new device

1. Sign in to the **same Apple ID** on both devices (Settings → Apple ID → iCloud).
2. Ensure **iCloud Drive** is enabled and the device has network access.
3. Open Cedar on your **primary device** first so any local-only data can export to iCloud.
4. On the new device, open Cedar and wait on the Inventory tab for 1–2 minutes (first import can be slow, especially with photos).
5. Check **Settings → iCloud Sync** for account status and recent import/export activity.

If data still does not appear, your closet may only exist on the primary device’s local database and never reached iCloud (for example, after a pre-CloudKit store reset). Use **Settings → Import from CSV** as a fallback.

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| Export failed: `CKErrorDomain error 2` | Production schema missing a new field (`partialFailure`) | Initialize Development schema on a device, deploy to Production (steps above) |
| Schema init fails in Simulator | CloudKit schema init is flaky without a real device/account | Use a physical iPhone/iPad signed into iCloud |
| Status Available, but Activity shows Export failed | Account OK; record sync failing | Check schema / Console; local inventory is usually still intact |

### AI Features

Add your [Anthropic API key](https://console.anthropic.com/) in the app under **Settings → Anthropic API Key**. The wand buttons in the item form are hidden when no key is configured.

- **Description wand** — appears next to the Description field when photos are attached
- **Price wand** — listing price (Poshmark) for sale items; donation value (fair market) for donation items

## Project Structure

```
Common/
├── START_HERE.md                  # Doc map and entry points
└── AI_ONBOARDING.md               # Context for AI assistants (gotchas, credentials, release)

Rack/                              # Source root (historical name; product is Cedar)
├── App/
│   ├── CedarApp.swift             # App entry point, injects managedObjectContext
│   ├── AppDelegate.swift          # CloudKit share acceptance
│   └── ContentView.swift          # Root navigation (TabView / NavigationSplitView)
├── Models/                        # NSManagedObject subclasses
│   ├── ClothingItem.swift
│   ├── Person.swift
│   ├── StorageLocation.swift
│   └── ItemPhoto.swift
├── Enums/                         # ItemStatus, ClothingType, ClothingSize, ShoeSize, AgeGroup, Gender, ItemCondition
├── Persistence/
│   ├── PersistenceController.swift  # Programmatic Core Data model + CloudKit container
│   └── CloudKitSyncMonitor.swift    # iCloud account status + sync event reporting for Settings
├── Views/
│   ├── Inventory/                 # InventoryListView, ItemDetailView, CameraView
│   ├── People/                    # PeopleView
│   ├── Locations/                 # LocationsView, AddLocationView
│   ├── Settings/                  # SettingsView (API key, iCloud sync status, family sharing, import/export)
│   ├── Sharing/                   # CloudSharingView (UICloudSharingController wrapper)
│   └── SplashScreenView.swift     # Splash + TartanView background
├── Services/
│   └── AIService.swift            # Claude API integration
├── Utilities/
│   ├── CSVImporter.swift          # CSV import logic
│   ├── CSVExporter.swift          # CSV export logic
│   └── JSONExporter.swift         # JSON export logic
├── Assets.xcassets/               # App icon (MacKinnon tartan + C)
├── Cedar.entitlements             # iOS/iPadOS: CloudKit container
├── Cedar-Mac.entitlements         # Mac Catalyst: App Sandbox + CloudKit
└── Info.plist                     # Version/build number, export compliance, Mac app category

scripts/
├── archive-for-testflight.sh      # Archive + export App Store IPA
├── upload-to-testflight.sh        # Upload IPA via App Store Connect API key
└── ExportOptions-app-store.plist  # Export options used by the archive script

project.yml                        # XcodeGen spec (generates Cedar.xcodeproj)
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed architecture map.

## Roadmap

- [x] CSV import UI (Settings → Import from CSV)
- [x] CSV export (Settings → Export to CSV)
- [x] Separate donation value from listing price (with fair-market AI estimation)
- [x] Export inventory to JSON

## License

MIT — see [LICENSE](LICENSE)

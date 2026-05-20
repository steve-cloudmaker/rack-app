# Cedar Closet Manager

A personal clothing inventory app for iPhone, iPad, and Mac Catalyst, built with SwiftUI and Core Data.

Cedar gives you a complete view of everything in your wardrobe — including kids clothes that have been outgrown — and helps you track what to keep, donate, or list on Poshmark.

## Features

- **Full inventory management** — add clothing items with photos (up to 5), brand, size, shoe size, color, condition, and category
- **Camera & photo library** — take new photos or pick from your library directly in the item form
- **Two-path status workflow** — Keep → For Sale → Listed → Sold, or Keep → For Donation → Given Away
- **Donation value tracking** — record fair market value on donated items (stored as `listingPrice`) for tax deduction purposes
- **Smart size picker** — baby (months), toddler (T-sizes), kids numeric, letter sizes, and shoe sizes, filtered by age group
- **People & locations** — assign items to family members and track physical storage locations (rack/row)
- **Poshmark tracking** — record listing price and sale price per item
- **Advanced filtering** — filter inventory by status, owner, location, and age group
- **AI-powered descriptions** — generate item descriptions from photos using Claude (bring your own API key)
- **AI price estimation** — get resale price suggestions via Claude
- **iCloud sync** — keep inventory in sync across all your iPhone and iPad devices
- **Family sharing** — share your closet with family members via CloudKit (Settings → Share Closet)
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
4. Set your Development Team in **Signing & Capabilities**
5. Build and run (`Cmd+R`)

### iCloud Sync

CloudKit is enabled by default via `iCloud.com.stevedaurora.cedar`. You'll need:

- A paid Apple Developer Program membership
- The App ID `com.stevedaurora.cedar` registered in the Developer portal with CloudKit enabled
- The iCloud container `iCloud.com.stevedaurora.cedar` created and linked

The app uses two Core Data store configurations:

- **Default** — your personal closet data (same CloudKit zone SwiftData used)
- **Shared** — data received from CloudKit share invitations

### Troubleshooting sync on a new device

1. Sign in to the **same Apple ID** on both devices (Settings → Apple ID → iCloud).
2. Ensure **iCloud Drive** is enabled and the device has network access.
3. Open Cedar on your **primary device** first so any local-only data can export to iCloud.
4. On the new device, open Cedar and wait on the Inventory tab for 1–2 minutes (first import can be slow, especially with photos).
5. Check **Settings → iCloud Sync** for account status and recent import/export activity.

If data still does not appear, your closet may only exist on the primary device’s local database and never reached iCloud (for example, after a pre-CloudKit store reset). Use **Settings → Import from CSV** as a fallback.

### AI Features

Add your [Anthropic API key](https://console.anthropic.com/) in the app under **Settings → Anthropic API Key**. The wand buttons in the item form are hidden when no key is configured.

- **Description wand** — appears next to the Description field when photos are attached
- **Price wand** — appears next to Listing Price / Donation Value for sale and donation items

## Project Structure

```
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
│   └── PersistenceController.swift  # Programmatic Core Data model + CloudKit container
├── Views/
│   ├── Inventory/                 # InventoryListView, ItemDetailView, CameraView
│   ├── People/                    # PeopleView
│   ├── Locations/                 # LocationsView, AddLocationView
│   ├── Settings/                  # SettingsView (API key, family sharing)
│   ├── Sharing/                   # CloudSharingView (UICloudSharingController wrapper)
│   └── SplashScreenView.swift     # Splash + TartanView background
├── Services/
│   └── AIService.swift            # Claude API integration
├── Utilities/
│   ├── CSVImporter.swift          # CSV import logic
│   └── CSVExporter.swift          # CSV export logic
├── Assets.xcassets/               # App icon (MacKinnon tartan + C)
├── Cedar.entitlements
└── Info.plist
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed architecture map.

## Roadmap

- [x] CSV import UI (Settings → Import from CSV)
- [x] CSV export (Settings → Export to CSV)
- [ ] Donation fair market value AI estimation (price wand currently targets Poshmark resale only)
- [ ] Export inventory to JSON

## License

MIT — see [LICENSE](LICENSE)

# Cedar

A personal clothing inventory app for iPhone and iPad, built with SwiftUI and SwiftData.

Cedar gives you a complete view of everything in your wardrobe — including kids clothes that have been outgrown — and helps you track what to keep, donate, or list on Poshmark.

## Features

- **Full inventory management** — add clothing items with photos (up to 5), brand, size, color, condition, and category
- **Camera & photo library** — take new photos or pick from your library directly in the item form
- **Two-path status workflow** — Keep → For Sale → Listed → Sold, or Keep → For Donation → Given Away
- **Donation value tracking** — record fair market value on donated items for tax deduction purposes
- **Smart size picker** — baby (months), toddler (T-sizes), kids numeric, and letter sizes, filtered by age group
- **People & locations** — assign items to family members and track physical storage locations (rack/row)
- **Poshmark tracking** — record listing price and sale price per item
- **AI-powered descriptions** — generate item descriptions from photos using Claude (bring your own API key)
- **AI price estimation** — get resale or fair market value suggestions via Claude
- **iCloud sync** — keep inventory in sync across all your iPhone and iPad devices
- **Shake to undo** — shake the device to undo a delete
- **MacKinnon Hunting tartan** — splash screen and subtle app background

## Tech Stack

- **SwiftUI** — UI framework (iOS 17+)
- **SwiftData + CloudKit** — persistence and iCloud sync
- **PhotosUI** — photo library picker
- **UIImagePickerController** — camera capture
- **Anthropic Claude API** — AI features (claude-haiku-4-5)

## Requirements

- iOS 17.0+
- iPadOS 17.0+
- macOS 14.0+ (Mac Catalyst)
- Xcode 15+
- Apple Developer Program membership (for iCloud sync)

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

### AI Features

Add your [Anthropic API key](https://console.anthropic.com/) in the app under **Settings → Anthropic API Key**. The wand buttons in the item form are hidden when no key is configured.

- **Description wand** — appears next to the Description field when photos are attached
- **Price wand** — appears next to Listing Price / Donation Value for sale and donation items

## Project Structure

```
Rack/                         # Source root (historical name, content is Cedar)
├── App/                      # CedarApp entry point, ContentView
├── Models/                   # SwiftData models
│   ├── ClothingItem.swift
│   ├── Person.swift
│   ├── StorageLocation.swift
│   └── ItemPhoto.swift
├── Enums/                    # ItemStatus, ClothingType, ClothingSize, AgeGroup, Gender, ItemCondition
├── Views/
│   ├── Inventory/            # InventoryListView, ItemDetailView
│   ├── People/               # PeopleView
│   ├── Locations/            # LocationsView, AddLocationView
│   └── Settings/             # SettingsView (API key)
├── Services/
│   └── AIService.swift       # Claude API integration
├── Assets.xcassets/          # App icon (MacKinnon tartan + C)
└── Utilities/
    └── CSVImporter.swift
```

## Roadmap

- [ ] Rename display name to "Cedar Closet Manager"
- [ ] Shoe size support
- [ ] CloudKit Sharing — collaborate with 1–2 family members (requires NSPersistentCloudKitContainer + CKShare)
- [ ] iPad split-view layout (NavigationSplitView)
- [ ] Advanced filtering (by owner, location, age group)
- [ ] CSV import UI

## License

MIT — see [LICENSE](LICENSE)

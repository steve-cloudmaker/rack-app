# Rack

A personal clothing inventory app for iPhone and iPad, built with SwiftUI and SwiftData.

Rack gives you a complete view of everything in your wardrobe — including kids clothes that have been outgrown — and helps you track what to keep, donate, or list on Poshmark.

## Features

- **Full inventory management** — add clothing items with photos (up to 5), brand, size, color, condition, and category
- **Two-path status workflow** — Keep → For Sale → Listed → Sold, or Keep → For Donation → Given Away
- **Smart size picker** — baby (months), toddler (T-sizes), kids numeric, and letter sizes, filtered by age group
- **People & locations** — assign items to family members and track physical storage locations (rack/row)
- **Poshmark tracking** — record listing price and sale price per item
- **AI-powered descriptions** — generate item descriptions from photos using Claude (bring your own API key)
- **Price estimation** — get AI-assisted resale price suggestions for items marked for sale
- **CSV bulk import** — import existing inventory from a spreadsheet
- **iCloud sync** — keep inventory in sync across iPhone and iPad (requires paid Apple Developer account)

## Tech Stack

- **SwiftUI** — UI framework
- **SwiftData** — persistence layer
- **CloudKit** — iCloud sync (optional, requires Apple Developer Program membership)
- **PhotosUI** — photo picker
- **Anthropic Claude API** — AI features (description generation, price estimation)

## Requirements

- iOS 17.0+
- iPadOS 17.0+
- macOS 14.0+ (Mac Catalyst)
- Xcode 15+

## Setup

1. Clone the repository
2. Open `Rack.xcodeproj` in Xcode
3. Set your Development Team in **Signing & Capabilities**
4. Build and run (`Cmd+R`)

### iCloud Sync

iCloud sync requires an [Apple Developer Program](https://developer.apple.com/programs/) membership. To enable it, change the `cloudKitDatabase` parameter in `RackApp.swift`:

```swift
// From:
let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)

// To:
let config = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.stevedaurora.rack"))
```

Then add the iCloud capability with your CloudKit container in **Signing & Capabilities**.

### AI Features

Add your [Anthropic API key](https://console.anthropic.com/) in the app under **Settings → Anthropic API Key**. AI features are disabled when no key is present.

## Project Structure

```
Rack/
├── App/                  # Entry point and root navigation
├── Models/               # SwiftData models (ClothingItem, Person, StorageLocation, ItemPhoto)
├── Enums/                # Typed enums (ItemStatus, ClothingType, ClothingSize, etc.)
├── Views/
│   ├── Inventory/        # Item list and detail/edit views
│   ├── People/           # People management
│   ├── Locations/        # Storage location management
│   └── Settings/         # API key and app settings
├── Services/             # AIService (Claude API integration)
└── Utilities/            # CSVImporter
```

## Roadmap

- [ ] Shoe size support
- [ ] iPad split-view layout (NavigationSplitView)
- [ ] Advanced filtering (by owner, location, age group)
- [ ] AI description generation (Claude vision)
- [ ] AI price estimation
- [ ] CSV import UI

## License

MIT — see [LICENSE](LICENSE)

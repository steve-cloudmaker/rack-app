# AI onboarding

Context for an AI assistant working on this repo with no memory of prior
sessions. Read [`START_HERE.md`](START_HERE.md) first for the doc map. This
file covers the parts that are not obvious from the code and are easy to get
wrong or re-diagnose from scratch.

## Product / naming facts

| Concept | Value |
|---|---|
| Product / display name | Cedar Closet Manager |
| Xcode target / scheme | `Cedar` |
| Source root | `Rack/` (historical; product renamed from Rack → Cedar) |
| Bundle ID | `com.stevedaurora.cedar` |
| CloudKit container | `iCloud.com.stevedaurora.cedar` |
| Development Team | `J7MM7A8SK8` (in `project.yml`) |
| GitHub repo | `steve-cloudmaker/rack-app` |
| Typical local path | `~/projects/cedar` (older clones may have been `inventory-app`) |
| Platforms | iPhone, iPad, Mac Catalyst (`SUPPORTS_MACCATALYST: YES`) |

Do not rename `Rack/` or the GitHub repo without an explicit user request —
both names are historical but wired into entitlements, docs, and habits.

## Current release state (as of 2026-10-02)

- Marketing version: **1.1** (`CFBundleShortVersionString` in `Rack/Info.plist`)
- Build: **4** (`CFBundleVersion`)
- CLI TestFlight archive + upload workflow is complete and proven
- Build 4 adds richer iCloud sync status (last import/export times, device vs
  iCloud counts) and **Push All Items to iCloud**

Before every new upload, bump `CFBundleVersion`. App Store Connect rejects
duplicate build numbers for the same app.

## Account / credentials (not in the repo)

- **Signing** — Automatic; team set in `project.yml` as `DEVELOPMENT_TEAM`.
  Edits made only in Xcode Signing & Capabilities are wiped by
  `xcodegen generate`.
- **App Store Connect API key** (for CLI upload) — typically:
  - Env: `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID` (often in `~/.zshrc`)
  - Key file: `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`
  - Never commit the `.p8` or put key material in tracked files
- **Anthropic API key** — user-supplied inside the app (`@AppStorage`
  `anthropic_api_key`); not required to build or ship
- **`.cursor/` and `.claude/`** — gitignored; local agent tooling only

## Architecture facts that are easy to miss

1. **Core Data model is programmatic** — defined in
   `PersistenceController.makeModel()`. There is no `.xcdatamodeld`. Adding
   attributes means updating the model *and* the `NSManagedObject` subclass.
2. **CloudKit store configuration must be named `Default`**, not `Private`.
   The private SQLite file is still `Cedar-private.sqlite`, but the Core Data
   *configuration* name is `Default` so it matches the zone SwiftData used
   historically. Changing this breaks existing iCloud data.
3. **Two stores** — `Default` (owner) + `Shared` (accepted CloudKit shares),
   same container ID.
4. **Status enum** — terminal donation status is **`Donated`**. Legacy stored
   value `"Given Away"` is still accepted via `ItemStatus(storedValue:)`.
5. **Lifecycle dates** — `saleDate` when Sold; `donatedDate` when Donated.
   Auto-filled to today on first transition in `ItemDetailView` if nil.
6. **JSON export** — `JSONExporter` produces a versioned backup (people,
   locations, items). Photos are not included (same as CSV).
7. **Mac Catalyst** — needs `LSApplicationCategoryType` in `Info.plist` and
   App Sandbox entitlements in `Rack/Cedar-Mac.entitlements` (wired via
   `CODE_SIGN_ENTITLEMENTS[sdk=macosx*]` in `project.yml`). iOS uses
   `Cedar.entitlements`.
8. **CloudKit field names** — Core Data attribute `saleDate` appears in
   CloudKit Console as **`CD_saleDate`** (camelCase, `CD_` prefix). Same for
   `CD_donatedDate`. Do not look for `CD_sale_date`.

## CloudKit schema (Development vs Production)

TestFlight and App Store builds use the **Production** CloudKit database.
Xcode Debug builds use **Development**. Adding Core Data attributes is not
enough for TestFlight — Production must receive those fields via a schema
deploy.

### When you add or change model fields

1. Update `PersistenceController.makeModel()`, the `NSManagedObject`
   subclass, UI/drafts, and CSV/JSON columns together.
2. Run a **Debug** build on a **physical device** signed into iCloud
   (simulators often fail schema init with opaque Core Data errors).
3. In the app: **Settings → Developer → Initialize CloudKit Development
   Schema** (`#if DEBUG` only; calls
   `PersistenceController.initializeDevelopmentSchema()`).
4. In [CloudKit Console](https://icloud.developer.apple.com/dashboard) →
   container `iCloud.com.stevedaurora.cedar` → **Development** → Schema →
   Record Types → confirm new fields on `CD_ClothingItem` (etc.).
5. **Deploy Schema Changes…** from Development → **Production**.
6. Confirm Production shows the same fields, then retest the TestFlight
   build (**Settings → iCloud Sync**).

### Implementation notes

- Schema init uses a **private-store-only** temporary
  `NSPersistentCloudKitContainer`. The Shared store cannot accept schema
  init writes; do not call `initializeCloudKitSchema` on the live dual-store
  container expecting it to work cleanly.
- Init must not block the main actor (`loadPersistentStores` may callback
  on main). The current API is `async` and runs work off the main queue.
- After Production deploy, record types/fields are additive forever — you
  can add fields, but not rename or delete them in Production.

## Gotchas already diagnosed and fixed — don't rediscover these

Check `git log --oneline` before assuming something is broken. In rough
chronological order:

1. **iCloud empty on a second device** — store configuration was named
   `Private` while existing CloudKit data lived in SwiftData's `Default`
   zone. Fix: use configuration name `Default`. See
   `PersistenceController` and ARCHITECTURE.md.
2. **TestFlight / App Store Mac Catalyst validation** — errors 90242
   (`LSApplicationCategoryType` missing) and 90296 (App Sandbox). Fix:
   lifestyle category in `Info.plist` + `Cedar-Mac.entitlements`.
3. **Inventory list not refreshing after edits on Mac Catalyst** — rows
   needed `@ObservedObject` on the item; save path should call
   `processPendingChanges()` after `save()`.
4. **CLI archive failed with "requires a development team"** — empty
   `DEVELOPMENT_TEAM` in `project.yml`. Fix: set team ID there and regenerate.
5. **Export failed with "PLA Update available" / no iOS Distribution
   cert** — Apple Developer Program License Agreement not accepted.
   Accept at [developer.apple.com/account](https://developer.apple.com/account),
   then retry archive/export. Looks like a cert problem; root cause is PLA.
6. **Upload / list-apps 403
   `REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED`** — App Store Connect
   agreements (Agreements, Tax, and Banking) are separate from the Developer
   portal EULA. Accept pending ASC agreements. **Banking "pending
   processing"** does **not** block TestFlight uploads once agreements are
   Active; only paid commerce needs banking fully cleared.
7. **Empty CloudKit container list in Xcode** — often means a pending
   Developer agreement, not that the container was deleted. Accept EULA and
   re-open Signing & Capabilities before recreating containers.
8. **`altool` "Cannot determine the Apple ID from Bundle ID"** — usually
   the same ASC agreement / permission gate as #6, not a missing app record.
   Confirm `xcrun altool --list-apps` can see Cedar before debugging bundle
   IDs.
9. **TestFlight Export failed: `CKErrorDomain error 2`** — that is
   `CKError.partialFailure`. Very often the Production schema is missing a
   new Core Data field. Example (1.1): Production had `CD_donatedDate` but
   not `CD_saleDate`; Development was also missing `CD_saleDate` until
   schema init on a device. Local inventory still works; only iCloud export
   fails. Fix: initialize Development schema → deploy to Production (see
   above). `CloudKitSyncMonitor` unpacks partial errors more fully in newer
   builds.
10. **CloudKit schema init fails in Simulator** — common; error may only
    say "A Core Data error occurred." Use a physical device with iCloud
    signed in. The Developer → Initialize Schema button is Debug-only.
11. **Schema init must not use `DispatchGroup.wait()` on the main actor** —
    can deadlock or fail oddly when `loadPersistentStores` callbacks hit
    main. Use the async private-store path in `PersistenceController`.

## Release pipeline (CLI)

```
# 1. Bump CFBundleVersion in Rack/Info.plist
# 2. Archive + export
./scripts/archive-for-testflight.sh
# → build/export/Cedar.ipa

# 3. Upload (needs ASC_API_* env + .p8)
./scripts/upload-to-testflight.sh
```

Archive uses `-allowProvisioningUpdates`. Export options live in
`scripts/ExportOptions-app-store.plist` (method `app-store-connect`, team
`J7MM7A8SK8`, automatic signing).

`build/` is gitignored.

## Conventions

- Prefer surgical changes; match existing SwiftUI / Core Data style.
- After editing `project.yml`, run `xcodegen generate`.
- Do not commit secrets, `.p8` keys, or local `.cursor/` / `.claude/` state.
- Commit messages explain *why* (follow recent `git log` style).
- When adding Core Data fields: update `makeModel()`, the managed object
  subclass, drafts/UI, and CSV/JSON import-export columns together — **and**
  run Development schema init on a device, then deploy to Production before
  expecting TestFlight sync to work.
- Photos are intentionally excluded from CSV/JSON export — do not "fix"
  that unless asked.

## Before recommending a fix

Grep the symptom in `README.md`, `ARCHITECTURE.md`, this file, and
`git log` first. Several issues look like generic signing or CloudKit
failures but already have project-specific root causes (PLA vs cert, ASC
agreements vs missing app, `Default` vs `Private` zone names, Production
schema missing new `CD_*` fields vs network/auth).

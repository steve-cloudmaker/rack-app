import CloudKit
import CoreData
import Foundation

/// Surfaces iCloud account status and NSPersistentCloudKitContainer import/export events for Settings UI and debugging.
@MainActor
@Observable
final class CloudKitSyncMonitor {
    static let shared = CloudKitSyncMonitor()

    private let containerID = "iCloud.com.stevedaurora.cedar"
    private let coreDataZoneName = "com.apple.coredata.cloudkit.zone"
    private let clothingRecordType = "CD_ClothingItem"

    private enum DefaultsKey {
        static let lastExportAt = "cloudkit.lastExportAt"
        static let lastImportAt = "cloudkit.lastImportAt"
        static let lastExportOK = "cloudkit.lastExportSucceeded"
        static let lastImportOK = "cloudkit.lastImportSucceeded"
    }

    var accountStatus: CKAccountStatus = .couldNotDetermine
    var accountStatusMessage: String = "Checking iCloud…"

    /// Most recent event line (in-progress or last failure detail).
    var activityMessage: String = "No sync activity yet"
    var isSyncing = false
    var activeOperation: String?

    var lastExportAt: Date?
    var lastImportAt: Date?
    var lastExportSucceeded: Bool?
    var lastImportSucceeded: Bool?

    var localItemCount: Int?
    var iCloudItemCount: Int?
    var iCloudCountError: String?
    var isRefreshingCounts = false

    private var exportStartedAt: Date?
    private var importStartedAt: Date?

    private init() {
        lastExportAt = UserDefaults.standard.object(forKey: DefaultsKey.lastExportAt) as? Date
        lastImportAt = UserDefaults.standard.object(forKey: DefaultsKey.lastImportAt) as? Date
        if UserDefaults.standard.object(forKey: DefaultsKey.lastExportOK) != nil {
            lastExportSucceeded = UserDefaults.standard.bool(forKey: DefaultsKey.lastExportOK)
        }
        if UserDefaults.standard.object(forKey: DefaultsKey.lastImportOK) != nil {
            lastImportSucceeded = UserDefaults.standard.bool(forKey: DefaultsKey.lastImportOK)
        }
    }

    var lastExportSummary: String {
        guard let lastExportAt else { return "Never on this device" }
        let when = Self.format(lastExportAt)
        switch lastExportSucceeded {
        case true: return when
        case false: return "Failed · \(when)"
        case nil: return when
        }
    }

    var lastImportSummary: String {
        guard let lastImportAt else { return "Never on this device" }
        let when = Self.format(lastImportAt)
        switch lastImportSucceeded {
        case true: return when
        case false: return "Failed · \(when)"
        case nil: return when
        }
    }

    var localCountSummary: String {
        guard let localItemCount else { return "—" }
        return "\(localItemCount)"
    }

    var iCloudCountSummary: String {
        if isRefreshingCounts { return "Checking…" }
        if let iCloudCountError { return "Unavailable" }
        guard let iCloudItemCount else { return "—" }
        return "\(iCloudItemCount)"
    }

    var countsFooter: String {
        if let iCloudCountError {
            return "iCloud count: \(iCloudCountError)"
        }
        guard let localItemCount, let iCloudItemCount else {
            return "Counts compare clothing items on this device with CD_ClothingItem records in your private iCloud database."
        }
        if localItemCount == iCloudItemCount {
            return "This device and iCloud report the same item count."
        }
        if localItemCount > iCloudItemCount {
            return "This device has \(localItemCount - iCloudItemCount) more item(s) than iCloud. Use “Push All Items to iCloud” if exports were blocked earlier (for example by a missing schema field)."
        }
        return "iCloud has \(iCloudItemCount - localItemCount) more item(s) than this device. Keep the app open to finish importing."
    }

    func refreshAccountStatus() async {
        let container = CKContainer(identifier: containerID)
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            accountStatusMessage = Self.message(for: status)
        } catch {
            accountStatus = .couldNotDetermine
            accountStatusMessage = "Could not check iCloud: \(error.localizedDescription)"
        }
    }

    func refreshCounts(context: NSManagedObjectContext) async {
        isRefreshingCounts = true
        defer { isRefreshingCounts = false }

        do {
            localItemCount = try context.performAndWait {
                try context.count(for: ClothingItem.fetchRequest())
            }
        } catch {
            localItemCount = nil
        }

        do {
            iCloudItemCount = try await fetchCloudClothingItemCount()
            iCloudCountError = nil
        } catch {
            iCloudItemCount = nil
            iCloudCountError = error.localizedDescription
            print("[Cedar] iCloud item count failed: \(error)")
        }
    }

    /// Bumps `updatedAt` on every local item so NSPersistentCloudKitContainer re-exports them.
    @discardableResult
    func pushAllItemsToiCloud(context: NSManagedObjectContext) throws -> Int {
        let items = try context.fetch(ClothingItem.fetchRequest())
        let now = Date()
        for item in items {
            item.updatedAt = now
        }
        try context.save()
        context.processPendingChanges()
        activityMessage = "Pushing \(items.count) item(s) to iCloud…"
        return items.count
    }

    func handleCloudKitEvent(_ event: NSPersistentCloudKitContainer.Event) {
        let inProgress = event.endDate == Date.distantPast
        let store = shortStoreLabel(event.storeIdentifier)
        let isPersonal = store == "Default" || store == "store"
        let type: String = switch event.type {
        case .import: "Import"
        case .export: "Export"
        case .setup: "Setup"
        @unknown default: "Sync"
        }

        if inProgress {
            isSyncing = true
            activeOperation = type
            switch event.type {
            case .export:
                exportStartedAt = event.startDate
                let countNote = localItemCount.map { " · \($0) local item(s)" } ?? ""
                let since = Self.format(event.startDate)
                activityMessage = "Export in progress since \(since)\(countNote)"
            case .import:
                importStartedAt = event.startDate
                let since = Self.format(event.startDate)
                activityMessage = "Import in progress since \(since)"
            case .setup:
                activityMessage = "Setting up iCloud sync…"
            @unknown default:
                activityMessage = "\(type) in progress…"
            }
            return
        }

        isSyncing = false
        activeOperation = nil
        let finishedAt = event.endDate == Date.distantPast ? Date() : event.endDate

        if event.succeeded {
            if isPersonal {
                switch event.type {
                case .export:
                    lastExportAt = finishedAt
                    lastExportSucceeded = true
                    persistExport()
                    activityMessage = "Export finished"
                case .import:
                    lastImportAt = finishedAt
                    lastImportSucceeded = true
                    persistImport()
                    activityMessage = "Import finished"
                case .setup:
                    activityMessage = "Setup finished"
                @unknown default:
                    activityMessage = "\(type) finished"
                }
            } else {
                activityMessage = "\(type) finished (\(store))"
            }
            // Refresh counts after a successful personal import/export.
            if isPersonal, event.type == .export || event.type == .import {
                Task {
                    let context = PersistenceController.shared.viewContext
                    await refreshCounts(context: context)
                }
            }
        } else if let error = event.error {
            let detail = Self.describe(error)
            if isPersonal {
                switch event.type {
                case .export:
                    lastExportAt = finishedAt
                    lastExportSucceeded = false
                    persistExport()
                    activityMessage = "Export failed: \(shortFailure(detail))"
                case .import:
                    lastImportAt = finishedAt
                    lastImportSucceeded = false
                    persistImport()
                    activityMessage = "Import failed: \(shortFailure(detail))"
                default:
                    activityMessage = "\(type) failed: \(shortFailure(detail))"
                }
            } else {
                activityMessage = "\(type) failed (\(store)): \(shortFailure(detail))"
            }
            print("[Cedar] CloudKit \(type) failed (\(store)): \(detail)")
            print("[Cedar] CloudKit underlying: \(error)")
        }
    }

    // MARK: - Private

    private func persistExport() {
        UserDefaults.standard.set(lastExportAt, forKey: DefaultsKey.lastExportAt)
        if let lastExportSucceeded {
            UserDefaults.standard.set(lastExportSucceeded, forKey: DefaultsKey.lastExportOK)
        }
    }

    private func persistImport() {
        UserDefaults.standard.set(lastImportAt, forKey: DefaultsKey.lastImportAt)
        if let lastImportSucceeded {
            UserDefaults.standard.set(lastImportSucceeded, forKey: DefaultsKey.lastImportOK)
        }
    }

    private func fetchCloudClothingItemCount() async throws -> Int {
        let database = CKContainer(identifier: containerID).privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: coreDataZoneName, ownerName: CKCurrentUserDefaultName)
        let query = CKQuery(recordType: clothingRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        var total = 0
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let page: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
            if let cursor {
                page = try await database.records(continuingMatchFrom: cursor, desiredKeys: [])
            } else {
                page = try await database.records(
                    matching: query,
                    inZoneWith: zoneID,
                    desiredKeys: [],
                    resultsLimit: 100
                )
            }
            total += page.matchResults.count
            cursor = page.queryCursor
        } while cursor != nil

        return total
    }

    private func shortStoreLabel(_ storeIdentifier: String) -> String {
        if storeIdentifier.isEmpty { return "store" }
        if storeIdentifier.contains("shared") { return "Shared" }
        if storeIdentifier.contains("private") { return "Default" }
        return storeIdentifier
    }

    private func shortFailure(_ detail: String) -> String {
        if detail.count <= 160 { return detail }
        return String(detail.prefix(157)) + "…"
    }

    private static func format(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    /// Unpacks CKError.partialFailure (code 2) and nested Core Data errors into a readable string.
    private static func describe(_ error: Error) -> String {
        let ns = error as NSError
        var parts: [String] = ["\(ns.domain) \(ns.code): \(ns.localizedDescription)"]

        if let ck = error as? CKError, ck.code == .partialFailure,
           let partial = ck.partialErrorsByItemID {
            let nested = partial.values
                .prefix(3)
                .map { describe($0) }
            if !nested.isEmpty {
                parts.append("partial: " + nested.joined(separator: " | "))
            }
        }

        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            parts.append("cause: \(describe(underlying))")
        }

        for key in ["NSDebugDescription", "NSLocalizedFailureReason"] {
            if let value = ns.userInfo[key] as? String, !value.isEmpty {
                parts.append(value)
            }
        }

        return parts.joined(separator: " — ")
    }

    private static func message(for status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "iCloud is available. Data syncs when the app is open or via background updates."
        case .noAccount:
            return "Sign in to iCloud in Settings to sync your closet."
        case .restricted:
            return "iCloud is restricted on this device."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Try again later."
        case .couldNotDetermine:
            return "Could not determine iCloud status."
        @unknown default:
            return "Unknown iCloud status."
        }
    }
}

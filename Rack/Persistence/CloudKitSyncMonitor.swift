import CloudKit
import CoreData
import Foundation

/// Surfaces iCloud account status and NSPersistentCloudKitContainer import/export events for Settings UI and debugging.
@MainActor
@Observable
final class CloudKitSyncMonitor {
    static let shared = CloudKitSyncMonitor()

    private let containerID = "iCloud.com.stevedaurora.cedar"

    var accountStatus: CKAccountStatus = .couldNotDetermine
    var accountStatusMessage: String = "Checking iCloud…"
    var lastEventMessage: String = "No sync activity yet"
    var isSyncing = false

    private init() {}

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

    func handleCloudKitEvent(_ event: NSPersistentCloudKitContainer.Event) {
        // endDate is Date.distantPast while an import/export is in progress
        isSyncing = event.endDate == Date.distantPast

        let store = shortStoreLabel(event.storeIdentifier)
        let type: String = switch event.type {
        case .import: "Import"
        case .export: "Export"
        case .setup: "Setup"
        @unknown default: "Sync"
        }
        if event.succeeded {
            lastEventMessage = "\(type) finished (\(store))"
        } else if let error = event.error {
            let detail = Self.describe(error)
            lastEventMessage = "\(type) failed (\(store)): \(detail)"
            print("[Cedar] CloudKit \(type) failed (\(store)): \(detail)")
            print("[Cedar] CloudKit underlying: \(error)")
        } else if isSyncing {
            lastEventMessage = "\(type) in progress (\(store))…"
        }
    }

    private func shortStoreLabel(_ storeIdentifier: String) -> String {
        if storeIdentifier.isEmpty { return "store" }
        if storeIdentifier.contains("shared") { return "Shared" }
        if storeIdentifier.contains("private") { return "Default" }
        return storeIdentifier
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

        // NSPersistentCloudKitContainer often nests useful strings under these keys.
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

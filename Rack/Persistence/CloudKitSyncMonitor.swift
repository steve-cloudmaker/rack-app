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

        let store = event.storeIdentifier.isEmpty ? "store" : event.storeIdentifier
        let type: String = switch event.type {
        case .import: "Import"
        case .export: "Export"
        case .setup: "Setup"
        @unknown default: "Sync"
        }
        if event.succeeded {
            lastEventMessage = "\(type) finished (\(store))"
        } else if let error = event.error {
            lastEventMessage = "\(type) failed: \(error.localizedDescription)"
        } else if isSyncing {
            lastEventMessage = "\(type) in progress (\(store))…"
        }
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

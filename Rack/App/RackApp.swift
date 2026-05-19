import SwiftUI
import SwiftData

@main
struct RackApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            ClothingItem.self,
            Person.self,
            StorageLocation.self,
            ItemPhoto.self
        ])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.stevedaurona.rack"))
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // The on-disk store was created before CloudKit was enabled and can't migrate.
            // Destroy it so SwiftData can create a CloudKit-compatible store from scratch.
            print("[RackApp] ModelContainer init failed: \(error). Resetting local store.")
            RackApp.destroyDefaultStore()
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to initialize ModelContainer after store reset: \(error)")
            }
        }
    }

    private static func destroyDefaultStore() {
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let names = ["default.store", "default.store-shm", "default.store-wal"]
        for name in names {
            try? FileManager.default.removeItem(at: appSupport.appending(path: name))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

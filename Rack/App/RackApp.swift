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
        // CloudKit sync requires a paid Apple Developer account.
        // To re-enable: change `.none` to `.private("iCloud.com.stevedaurora.rack")`
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

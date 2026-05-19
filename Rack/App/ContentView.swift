import SwiftUI

struct ContentView: View {
    @Environment(\.undoManager) private var undoManager
    @State private var showSplash = true

    var body: some View {
        ZStack {
            TabView {
                InventoryListView()
                    .tabItem { Label("Inventory", systemImage: "tshirt") }

                PeopleView()
                    .tabItem { Label("People", systemImage: "person.2") }

                LocationsView()
                    .tabItem { Label("Locations", systemImage: "archivebox") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .onAppear {
                PersistenceController.shared.viewContext.undoManager = undoManager
            }

            if showSplash {
                SplashScreenView { showSplash = false }
                    .ignoresSafeArea()
                    .zIndex(1)
            }
        }
    }
}

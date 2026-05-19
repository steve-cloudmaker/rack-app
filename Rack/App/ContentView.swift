import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @State private var showSplash = true

    var body: some View {
        ZStack {
        TabView {
            InventoryListView()
                .tabItem {
                    Label("Inventory", systemImage: "tshirt")
                }

            PeopleView()
                .tabItem {
                    Label("People", systemImage: "person.2")
                }

            LocationsView()
                .tabItem {
                    Label("Locations", systemImage: "archivebox")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            modelContext.undoManager = undoManager
        }

        if showSplash {
            SplashScreenView { showSplash = false }
                .ignoresSafeArea()
                .zIndex(1)
        }
        } // ZStack
    }
}

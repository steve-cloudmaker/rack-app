import SwiftUI

struct ContentView: View {
    var body: some View {
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
    }
}

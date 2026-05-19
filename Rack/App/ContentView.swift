import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.undoManager) private var undoManager
    @State private var showSplash = true
    @State private var selectedSection: AppSection? = .inventory

    var body: some View {
        ZStack {
            if sizeClass == .regular {
                splitLayout
            } else {
                tabLayout
            }

            if showSplash {
                SplashScreenView { showSplash = false }
                    .ignoresSafeArea()
                    .zIndex(1)
            }
        }
        .onAppear {
            PersistenceController.shared.viewContext.undoManager = undoManager
        }
    }

    // MARK: - iPad

    private var splitLayout: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("Cedar")
        } detail: {
            switch selectedSection ?? .inventory {
            case .inventory: InventoryListView()
            case .people:    PeopleView()
            case .locations: LocationsView()
            case .settings:  SettingsView()
            }
        }
    }

    // MARK: - iPhone

    private var tabLayout: some View {
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
    }
}

// MARK: -

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case inventory, people, locations, settings
    var id: Self { self }

    var title: String {
        switch self {
        case .inventory: "Inventory"
        case .people:    "People"
        case .locations: "Locations"
        case .settings:  "Settings"
        }
    }

    var icon: String {
        switch self {
        case .inventory: "tshirt"
        case .people:    "person.2"
        case .locations: "archivebox"
        case .settings:  "gear"
        }
    }
}

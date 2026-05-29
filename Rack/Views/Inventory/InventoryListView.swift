import SwiftUI
import CoreData

struct InventoryListView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClothingItem.updatedAt, ascending: false)],
        animation: .default
    ) private var items: FetchedResults<ClothingItem>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)])
    private var people: FetchedResults<Person>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StorageLocation.name, ascending: true)])
    private var locations: FetchedResults<StorageLocation>

    @State private var searchText      = ""
    @State private var selectedStatus:   ItemStatus?
    @State private var selectedOwner:    UUID?
    @State private var selectedLocation: UUID?
    @State private var selectedAgeGroup: AgeGroup?
    @State private var showingFilters  = false
    @State private var showingAddItem  = false

    var isFiltering: Bool {
        selectedStatus != nil || selectedOwner != nil ||
        selectedLocation != nil || selectedAgeGroup != nil
    }

    var activeFilterCount: Int {
        [selectedStatus != nil, selectedOwner != nil,
         selectedLocation != nil, selectedAgeGroup != nil].filter { $0 }.count
    }

    var filteredItems: [ClothingItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty
                || item.displayTitle.localizedCaseInsensitiveContains(searchText)
                || item.brand.localizedCaseInsensitiveContains(searchText)
                || item.color.localizedCaseInsensitiveContains(searchText)
            let matchesStatus    = selectedStatus   == nil || item.status       == selectedStatus
            let matchesOwner     = selectedOwner    == nil || item.owner?.id    == selectedOwner
            let matchesLocation  = selectedLocation == nil || item.location?.id == selectedLocation
            let matchesAgeGroup  = selectedAgeGroup == nil || item.ageGroup     == selectedAgeGroup
            return matchesSearch && matchesStatus && matchesOwner && matchesLocation && matchesAgeGroup
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemRowView(item: item)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground).opacity(0.70))
                }
                .onDelete(perform: deleteItems)
            }
            .scrollContentBackground(.hidden)
            .background(TartanView().ignoresSafeArea().opacity(0.20))
            .searchable(text: $searchText, prompt: "Search items")
            .safeAreaInset(edge: .top, spacing: 0) {
                if isFiltering { filterChips }
            }
            .navigationTitle("Cedar Closet Manager")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: isFiltering
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                        .overlay(alignment: .topTrailing) {
                            if activeFilterCount > 1 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(.blue, in: Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                ItemDetailView(item: nil)
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheetView(
                    selectedStatus:   $selectedStatus,
                    selectedOwner:    $selectedOwner,
                    selectedLocation: $selectedLocation,
                    selectedAgeGroup: $selectedAgeGroup
                )
            }
            .overlay {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        !searchText.isEmpty || isFiltering ? "No Matches" : "No Items",
                        systemImage: "tshirt",
                        description: Text(
                            !searchText.isEmpty || isFiltering
                                ? "Try adjusting your search or filters."
                                : "Tap + to add your first item."
                        )
                    )
                }
            }
        }
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let status = selectedStatus {
                    FilterChip(label: status.displayName) { selectedStatus = nil }
                }
                if let ownerID = selectedOwner,
                   let name = people.first(where: { $0.id == ownerID })?.name {
                    FilterChip(label: name) { selectedOwner = nil }
                }
                if let locationID = selectedLocation,
                   let label = locations.first(where: { $0.id == locationID })?.displayLabel {
                    FilterChip(label: label) { selectedLocation = nil }
                }
                if let age = selectedAgeGroup {
                    FilterChip(label: age.displayName) { selectedAgeGroup = nil }
                }
                Button("Clear All") {
                    selectedStatus = nil; selectedOwner = nil
                    selectedLocation = nil; selectedAgeGroup = nil
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }

    // MARK: - Actions

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets { managedObjectContext.delete(filteredItems[index]) }
        try? managedObjectContext.save()
    }
}

// MARK: - Filter chip button

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Text(label)
                Image(systemName: "xmark")
                    .imageScale(.small)
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter sheet

struct FilterSheetView: View {
    @Binding var selectedStatus:   ItemStatus?
    @Binding var selectedOwner:    UUID?
    @Binding var selectedLocation: UUID?
    @Binding var selectedAgeGroup: AgeGroup?

    @Environment(\.dismiss) private var dismiss

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)])
    private var people: FetchedResults<Person>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StorageLocation.name, ascending: true)])
    private var locations: FetchedResults<StorageLocation>

    var isFiltering: Bool {
        selectedStatus != nil || selectedOwner != nil ||
        selectedLocation != nil || selectedAgeGroup != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Status", selection: $selectedStatus) {
                        Text("All Statuses").tag(Optional<ItemStatus>.none)
                        ForEach(ItemStatus.allCases) { s in
                            Text(s.displayName).tag(Optional(s))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if !people.isEmpty {
                    Section("Owner") {
                        Picker("Owner", selection: $selectedOwner) {
                            Text("All Owners").tag(Optional<UUID>.none)
                            ForEach(people) { p in
                                Text(p.name).tag(Optional(p.id))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }

                if !locations.isEmpty {
                    Section("Location") {
                        Picker("Location", selection: $selectedLocation) {
                            Text("All Locations").tag(Optional<UUID>.none)
                            ForEach(locations) { l in
                                Text(l.displayLabel).tag(Optional(l.id))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }

                Section("Age Group") {
                    Picker("Age Group", selection: $selectedAgeGroup) {
                        Text("All Ages").tag(Optional<AgeGroup>.none)
                        ForEach(AgeGroup.allCases) { a in
                            Text(a.displayName).tag(Optional(a))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if isFiltering {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            selectedStatus = nil; selectedOwner = nil
                            selectedLocation = nil; selectedAgeGroup = nil
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Row & badge (unchanged)

struct ItemRowView: View {
    @ObservedObject var item: ClothingItem

    var body: some View {
        HStack(spacing: 12) {
            if let photo = item.sortedPhotos.first,
               let data = photo.imageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: item.clothingType == .shoes ? "shoe" : "tshirt")
                            .foregroundStyle(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let sizeDisplay = item.clothingType == .shoes
                        ? item.shoeSize?.contextualDisplayName
                        : item.size?.displayName {
                        Text(sizeDisplay)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let owner = item.owner {
                        Text("·").foregroundStyle(.secondary)
                        Text(owner.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
            StatusBadge(status: item.status)
        }
        .padding(.vertical, 2)
    }
}

struct StatusBadge: View {
    let status: ItemStatus

    var color: Color {
        switch status {
        case .keep:        return .blue
        case .forSale:     return .orange
        case .listed:      return .purple
        case .sold:        return .green
        case .forDonation: return .teal
        case .givenAway:   return .gray
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

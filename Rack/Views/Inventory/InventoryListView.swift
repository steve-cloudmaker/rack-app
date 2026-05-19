import SwiftUI
import SwiftData

struct InventoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.updatedAt, order: .reverse) private var items: [ClothingItem]

    @State private var searchText = ""
    @State private var selectedStatus: ItemStatus?
    @State private var showingAddItem = false

    var filteredItems: [ClothingItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                item.brand.localizedCaseInsensitiveContains(searchText) ||
                item.color.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || item.status == selectedStatus
            return matchesSearch && matchesStatus
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
            .navigationTitle("Cedar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    statusFilterMenu
                }
            }
            .sheet(isPresented: $showingAddItem) {
                ItemDetailView(item: nil)
            }
            .overlay {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Items" : "No Results",
                        systemImage: "tshirt",
                        description: Text(searchText.isEmpty ? "Tap + to add your first item." : "Try a different search.")
                    )
                }
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredItems[index])
        }
    }

    private var statusFilterMenu: some View {
        Menu {
            Button("All") { selectedStatus = nil }
            Divider()
            ForEach(ItemStatus.allCases) { status in
                Button(status.displayName) { selectedStatus = status }
            }
        } label: {
            Label(
                selectedStatus?.displayName ?? "Filter",
                systemImage: selectedStatus == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }
}

struct ItemRowView: View {
    let item: ClothingItem

    var body: some View {
        HStack(spacing: 12) {
            if let photo = item.sortedPhotos.first, let data = photo.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "tshirt").foregroundStyle(.secondary))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let size = item.size {
                        Text(size.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let owner = item.owner {
                        Text("·")
                            .foregroundStyle(.secondary)
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
        case .keep: return .blue
        case .forSale: return .orange
        case .listed: return .purple
        case .sold: return .green
        case .forDonation: return .teal
        case .givenAway: return .gray
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

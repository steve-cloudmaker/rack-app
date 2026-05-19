import SwiftUI
import SwiftData

struct LocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StorageLocation.name) private var locations: [StorageLocation]
    @State private var showingAddLocation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(locations) { location in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.displayLabel)
                        Text("\(location.items.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground).opacity(0.70))
                }
                .onDelete(perform: deleteLocations)
            }
            .scrollContentBackground(.hidden)
            .background(TartanView().ignoresSafeArea().opacity(0.20))
            .navigationTitle("Locations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddLocation = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if locations.isEmpty {
                    ContentUnavailableView(
                        "No Locations",
                        systemImage: "archivebox",
                        description: Text("Add locations to track where items are stored.")
                    )
                }
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView()
            }
        }
    }

    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(locations[index])
        }
    }
}

struct AddLocationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var rack = ""
    @State private var row = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("Name (e.g. Storage Unit A)", text: $name)
                    TextField("Rack (optional)", text: $rack)
                    TextField("Row (optional)", text: $row)
                }

                Section {
                    Text("Preview: \(previewLabel)")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var previewLabel: String {
        let location = StorageLocation(name: name, rack: rack, row: row)
        return location.displayLabel
    }

    private func save() {
        let location = StorageLocation(
            name: name.trimmingCharacters(in: .whitespaces),
            rack: rack.trimmingCharacters(in: .whitespaces),
            row: row.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(location)
        dismiss()
    }
}

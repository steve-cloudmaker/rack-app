import SwiftUI
import SwiftData

struct PeopleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]
    @State private var showingAddPerson = false
    @State private var newPersonName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(people) { person in
                    HStack {
                        Text(person.name)
                        Spacer()
                        Text("\(person.items.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deletePeople)
            }
            .navigationTitle("People")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddPerson = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if people.isEmpty {
                    ContentUnavailableView(
                        "No People",
                        systemImage: "person.2",
                        description: Text("Add people to assign items to them.")
                    )
                }
            }
            .alert("New Person", isPresented: $showingAddPerson) {
                TextField("Name", text: $newPersonName)
                Button("Add") { addPerson() }
                Button("Cancel", role: .cancel) { newPersonName = "" }
            }
        }
    }

    private func addPerson() {
        guard !newPersonName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        modelContext.insert(Person(name: newPersonName.trimmingCharacters(in: .whitespaces)))
        newPersonName = ""
    }

    private func deletePeople(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(people[index])
        }
    }
}

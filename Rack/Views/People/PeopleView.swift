import SwiftUI
import CoreData

struct PeopleView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)],
        animation: .default
    ) private var people: FetchedResults<Person>

    @State private var showingAddPerson = false
    @State private var newPersonName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(people) { person in
                    HStack {
                        Text(person.name)
                        Spacer()
                        Text("\(person.items?.count ?? 0) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground).opacity(0.70))
                }
                .onDelete(perform: deletePeople)
            }
            .scrollContentBackground(.hidden)
            .background(TartanView().ignoresSafeArea().opacity(0.20))
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
        let trimmed = newPersonName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        _ = Person(name: trimmed, context: managedObjectContext)
        try? managedObjectContext.save()
        newPersonName = ""
    }

    private func deletePeople(at offsets: IndexSet) {
        for index in offsets { managedObjectContext.delete(people[index]) }
        try? managedObjectContext.save()
    }
}

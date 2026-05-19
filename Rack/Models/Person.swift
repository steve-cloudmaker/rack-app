import CoreData
import Foundation

@objc(Person)
class Person: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var createdAt: Date
    @NSManaged var items: NSSet?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        id        = UUID()
        createdAt = Date()
        name      = ""
    }

    convenience init(name: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = name
    }

    var clothingItemsArray: [ClothingItem] {
        (items as? Set<ClothingItem>).map(Array.init) ?? []
    }

}

extension Person: Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Person> {
        NSFetchRequest<Person>(entityName: "Person")
    }
}

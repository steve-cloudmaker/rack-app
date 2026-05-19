import CoreData
import Foundation

@objc(StorageLocation)
class StorageLocation: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var rack: String
    @NSManaged var row: String
    @NSManaged var createdAt: Date
    @NSManaged var items: NSSet?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        id        = UUID()
        createdAt = Date()
        name      = ""
        rack      = ""
        row       = ""
    }

    convenience init(name: String, rack: String = "", row: String = "", context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = name
        self.rack = rack
        self.row  = row
    }

    var displayLabel: String {
        var parts: [String] = [name]
        if !rack.isEmpty { parts.append("Rack \(rack)") }
        if !row.isEmpty  { parts.append("Row \(row)")  }
        return parts.joined(separator: " · ")
    }

}

extension StorageLocation: Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StorageLocation> {
        NSFetchRequest<StorageLocation>(entityName: "StorageLocation")
    }
}

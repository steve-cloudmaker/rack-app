import CoreData
import Foundation

@objc(ItemPhoto)
class ItemPhoto: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var sortOrder: Int64
    @NSManaged var imageData: Data?
    @NSManaged var item: ClothingItem?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        id        = UUID()
        sortOrder = 0
    }
}

extension ItemPhoto: Identifiable {}

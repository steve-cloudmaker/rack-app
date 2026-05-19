import CoreData
import Foundation

@objc(ClothingItem)
class ClothingItem: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var itemDescription: String
    @NSManaged var brand: String
    @NSManaged var color: String
    @NSManaged var statusRaw: String
    @NSManaged var clothingTypeRaw: String
    @NSManaged var ageGroupRaw: String
    @NSManaged var genderRaw: String
    @NSManaged var conditionRaw: String
    @NSManaged var sizeRaw: String
    @NSManaged var shoeSizeRaw: String
    @NSManaged var listingPrice: NSNumber?
    @NSManaged var salePrice: NSNumber?
    @NSManaged var photos: NSSet?
    @NSManaged var owner: Person?
    @NSManaged var location: StorageLocation?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        id         = UUID()
        createdAt  = Date()
        updatedAt  = Date()
        itemDescription = ""
        brand      = ""
        color      = ""
        statusRaw       = ItemStatus.keep.rawValue
        clothingTypeRaw = ClothingType.shirts.rawValue
        ageGroupRaw     = AgeGroup.adult.rawValue
        genderRaw       = Gender.unisex.rawValue
        conditionRaw    = ItemCondition.good.rawValue
        sizeRaw         = ""
        shoeSizeRaw     = ""
    }

    // MARK: - Typed accessors

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .keep }
        set { statusRaw = newValue.rawValue; updatedAt = Date() }
    }

    var clothingType: ClothingType {
        get { ClothingType(rawValue: clothingTypeRaw) ?? .shirts }
        set { clothingTypeRaw = newValue.rawValue; updatedAt = Date() }
    }

    var ageGroup: AgeGroup {
        get { AgeGroup(rawValue: ageGroupRaw) ?? .adult }
        set { ageGroupRaw = newValue.rawValue; updatedAt = Date() }
    }

    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .unisex }
        set { genderRaw = newValue.rawValue; updatedAt = Date() }
    }

    var condition: ItemCondition {
        get { ItemCondition(rawValue: conditionRaw) ?? .good }
        set { conditionRaw = newValue.rawValue; updatedAt = Date() }
    }

    var size: ClothingSize? {
        get { ClothingSize(rawValue: sizeRaw) }
        set { sizeRaw = newValue?.rawValue ?? ""; updatedAt = Date() }
    }

    var shoeSize: ShoeSize? {
        get { ShoeSize(rawValue: shoeSizeRaw) }
        set { shoeSizeRaw = newValue?.rawValue ?? ""; updatedAt = Date() }
    }

    // MARK: - Derived helpers

    var sortedPhotos: [ItemPhoto] {
        guard let set = photos as? Set<ItemPhoto> else { return [] }
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }

    var displayTitle: String {
        let parts = [brand, itemDescription].filter { !$0.isEmpty }
        return parts.isEmpty ? "Untitled Item" : parts.joined(separator: " ")
    }

    var canHaveListingPrice: Bool {
        status == .forSale || status == .listed || status == .sold
    }

}

extension ClothingItem: Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ClothingItem> {
        NSFetchRequest<ClothingItem>(entityName: "ClothingItem")
    }
}

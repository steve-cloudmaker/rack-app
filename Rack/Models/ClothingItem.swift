import SwiftData
import Foundation

@Model
final class ClothingItem {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Core attributes stored as primitives for CloudKit compatibility
    var itemDescription: String = ""
    var brand: String = ""
    var color: String = ""

    var statusRaw: String = ItemStatus.keep.rawValue
    var clothingTypeRaw: String = ClothingType.shirts.rawValue
    var ageGroupRaw: String = AgeGroup.adult.rawValue
    var genderRaw: String = Gender.unisex.rawValue
    var conditionRaw: String = ItemCondition.good.rawValue
    var sizeRaw: String = ""

    var listingPrice: Double?
    var salePrice: Double?

    @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.item)
    var photos: [ItemPhoto] = []

    var owner: Person?
    var location: StorageLocation?

    init() {}

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

    // MARK: - Derived helpers

    var sortedPhotos: [ItemPhoto] {
        photos.sorted { $0.sortOrder < $1.sortOrder }
    }

    var displayTitle: String {
        let parts = [brand, itemDescription].filter { !$0.isEmpty }
        return parts.isEmpty ? "Untitled Item" : parts.joined(separator: " ")
    }

    var canHaveListingPrice: Bool {
        status == .forSale || status == .listed || status == .sold
    }
}

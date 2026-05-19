import SwiftData
import Foundation

@Model
final class ItemPhoto {
    var id: UUID = UUID()
    var sortOrder: Int = 0
    @Attribute(.externalStorage) var imageData: Data?
    var item: ClothingItem?

    init(imageData: Data, sortOrder: Int = 0) {
        self.imageData = imageData
        self.sortOrder = sortOrder
    }
}

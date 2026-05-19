import SwiftData
import Foundation

@Model
final class Person {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \ClothingItem.owner)
    var items: [ClothingItem]?

    init(name: String) {
        self.name = name
    }
}

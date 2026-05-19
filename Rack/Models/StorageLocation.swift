import SwiftData
import Foundation

@Model
final class StorageLocation {
    var id: UUID = UUID()
    var name: String = ""
    var rack: String = ""
    var row: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \ClothingItem.location)
    var items: [ClothingItem] = []

    init(name: String, rack: String = "", row: String = "") {
        self.name = name
        self.rack = rack
        self.row = row
    }

    var displayLabel: String {
        var parts: [String] = [name]
        if !rack.isEmpty { parts.append("Rack \(rack)") }
        if !row.isEmpty { parts.append("Row \(row)") }
        return parts.joined(separator: " · ")
    }
}

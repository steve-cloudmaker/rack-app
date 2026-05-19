import Foundation
import SwiftData

struct CSVImportError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct CSVImporter {
    static let expectedHeaders = ["description", "brand", "color", "size", "type", "ageGroup", "gender", "condition", "status", "owner", "rack", "row", "location", "listingPrice", "salePrice"]

    static func `import`(from url: URL, context: ModelContext) throws -> Int {
        let contents = try String(contentsOf: url, encoding: .utf8)
        let rows = contents.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard let headerRow = rows.first else { throw CSVImportError(message: "File is empty") }

        let headers = headerRow.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard headers.contains("description") || headers.contains("brand") else {
            throw CSVImportError(message: "CSV must include at least a 'description' or 'brand' column")
        }

        var importedCount = 0
        for row in rows.dropFirst() {
            let values = parseCSVRow(row)
            guard values.count == headers.count else { continue }
            let fields = Dictionary(uniqueKeysWithValues: zip(headers, values))

            let item = ClothingItem()
            item.itemDescription = fields["description"] ?? ""
            item.brand = fields["brand"] ?? ""
            item.color = fields["color"] ?? ""

            if let sizeStr = fields["size"], let size = ClothingSize(rawValue: sizeStr) {
                item.size = size
            }
            if let typeStr = fields["type"], let type = ClothingType(rawValue: typeStr) {
                item.clothingType = type
            }
            if let ageStr = fields["agegroup"], let age = AgeGroup(rawValue: ageStr.capitalized) {
                item.ageGroup = age
            }
            if let genderStr = fields["gender"], let gender = Gender(rawValue: genderStr.capitalized) {
                item.gender = gender
            }
            if let condStr = fields["condition"], let cond = ItemCondition(rawValue: condStr) {
                item.condition = cond
            }
            if let statusStr = fields["status"], let status = ItemStatus(rawValue: statusStr) {
                item.status = status
            }
            if let priceStr = fields["listingprice"], let price = Double(priceStr) {
                item.listingPrice = price
            }
            if let priceStr = fields["saleprice"], let price = Double(priceStr) {
                item.salePrice = price
            }

            context.insert(item)
            importedCount += 1
        }
        return importedCount
    }

    private static func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}

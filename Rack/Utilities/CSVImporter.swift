import Foundation
import CoreData

struct CSVImportError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct CSVImporter {
    static let expectedHeaders = ["description", "brand", "color", "size", "shoeSize", "type", "ageGroup", "gender", "condition", "status", "owner", "rack", "row", "location", "listingPrice", "donationValue", "salePrice"]

    static func `import`(from url: URL, context: NSManagedObjectContext) throws -> Int {
        let contents = try String(contentsOf: url, encoding: .utf8)
        let rows = contents.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard let headerRow = rows.first else { throw CSVImportError(message: "File is empty") }

        let headers = headerRow.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard headers.contains("description") || headers.contains("brand") else {
            throw CSVImportError(message: "CSV must include at least a 'description' or 'brand' column")
        }

        var peopleByName = try fetchPeople(context: context)
        var locationsByName = try fetchLocations(context: context)

        var importedCount = 0
        for row in rows.dropFirst() {
            let values = parseCSVRow(row)
            guard values.count == headers.count else { continue }
            let fields = Dictionary(uniqueKeysWithValues: zip(headers, values))

            let item = ClothingItem(context: context)
            item.itemDescription = fields["description"] ?? ""
            item.brand = fields["brand"] ?? ""
            item.color = fields["color"] ?? ""

            if let sizeStr = fields["size"],     let size  = ClothingSize(rawValue: sizeStr)    { item.size     = size  }
            if let sizeStr = fields["shoesize"], let size  = ShoeSize(rawValue: sizeStr)        { item.shoeSize = size  }
            if let typeStr = fields["type"],     let type  = ClothingType(rawValue: typeStr)    { item.clothingType = type }
            if let ageStr  = fields["agegroup"], let age   = AgeGroup(rawValue: ageStr.capitalized)   { item.ageGroup = age   }
            if let genStr  = fields["gender"],   let gen   = Gender(rawValue: genStr.capitalized)     { item.gender   = gen   }
            if let condStr = fields["condition"],let cond  = ItemCondition(rawValue: condStr)         { item.condition = cond }
            if let statStr = fields["status"],   let stat  = ItemStatus(rawValue: statStr)            { item.status   = stat  }
            if let priceStr = fields["listingprice"], let price = Double(priceStr) { item.listingPrice = NSNumber(value: price) }
            if let priceStr = fields["donationvalue"], let price = Double(priceStr) { item.donationValue = NSNumber(value: price) }
            if let priceStr = fields["saleprice"],    let price = Double(priceStr) { item.salePrice    = NSNumber(value: price) }

            if let ownerName = fields["owner"]?.trimmingCharacters(in: .whitespacesAndNewlines), !ownerName.isEmpty {
                item.owner = person(named: ownerName, cache: &peopleByName, context: context)
            }

            if let locationName = fields["location"]?.trimmingCharacters(in: .whitespacesAndNewlines), !locationName.isEmpty {
                item.location = location(
                    named: locationName,
                    rack: fields["rack"] ?? "",
                    row: fields["row"] ?? "",
                    cache: &locationsByName,
                    context: context
                )
            }

            importedCount += 1
        }
        try context.save()
        return importedCount
    }

    private static func fetchPeople(context: NSManagedObjectContext) throws -> [String: Person] {
        let request = Person.fetchRequest()
        let people = try context.fetch(request)
        return Dictionary(uniqueKeysWithValues: people.map { ($0.name.lowercased(), $0) })
    }

    private static func fetchLocations(context: NSManagedObjectContext) throws -> [String: StorageLocation] {
        let request = StorageLocation.fetchRequest()
        let locations = try context.fetch(request)
        return Dictionary(uniqueKeysWithValues: locations.map { ($0.name.lowercased(), $0) })
    }

    private static func person(named name: String, cache: inout [String: Person], context: NSManagedObjectContext) -> Person {
        let key = name.lowercased()
        if let existing = cache[key] { return existing }
        let person = Person(name: name, context: context)
        cache[key] = person
        return person
    }

    private static func location(
        named name: String,
        rack: String,
        row: String,
        cache: inout [String: StorageLocation],
        context: NSManagedObjectContext
    ) -> StorageLocation {
        let key = name.lowercased()
        if let existing = cache[key] { return existing }
        let location = StorageLocation(name: name, rack: rack, row: row, context: context)
        cache[key] = location
        return location
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

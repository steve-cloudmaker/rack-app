import CoreData
import Foundation

struct JSONExportError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct JSONExporter {
    static let exportVersion = 1

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    /// Builds a JSON document for the full inventory (people, locations, items).
    static func exportJSON(context: NSManagedObjectContext) throws -> Data {
        let payload = try buildPayload(context: context)
        guard !payload.items.isEmpty else {
            throw JSONExportError(message: "No items to export. Add clothing to your inventory first.")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    /// Writes JSON to a temporary file for sharing via the system share sheet.
    static func exportToTemporaryFile(context: NSManagedObjectContext) throws -> URL {
        let data = try exportJSON(context: context)
        let date = dateFormatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("cedar-closet-\(date).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func buildPayload(context: NSManagedObjectContext) throws -> CedarExport {
        let people = try fetchPeople(context: context)
        let locations = try fetchLocations(context: context)
        let items = try fetchItems(context: context)

        return CedarExport(
            exportVersion: exportVersion,
            exportedAt: Date(),
            people: people.map(ExportPerson.init),
            locations: locations.map(ExportLocation.init),
            items: items.map(ExportItem.init)
        )
    }

    private static func fetchPeople(context: NSManagedObjectContext) throws -> [Person] {
        let request = Person.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Person.name, ascending: true)]
        return try context.fetch(request)
    }

    private static func fetchLocations(context: NSManagedObjectContext) throws -> [StorageLocation] {
        let request = StorageLocation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StorageLocation.name, ascending: true)]
        return try context.fetch(request)
    }

    private static func fetchItems(context: NSManagedObjectContext) throws -> [ClothingItem] {
        let request = ClothingItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClothingItem.updatedAt, ascending: false)]
        return try context.fetch(request)
    }
}

// MARK: - Export schema

struct CedarExport: Codable {
    let exportVersion: Int
    let exportedAt: Date
    let people: [ExportPerson]
    let locations: [ExportLocation]
    let items: [ExportItem]
}

struct ExportPerson: Codable {
    let id: UUID
    let name: String
    let createdAt: Date

    init(_ person: Person) {
        id = person.id
        name = person.name
        createdAt = person.createdAt
    }
}

struct ExportLocation: Codable {
    let id: UUID
    let name: String
    let rack: String
    let row: String
    let createdAt: Date

    init(_ location: StorageLocation) {
        id = location.id
        name = location.name
        rack = location.rack
        row = location.row
        createdAt = location.createdAt
    }
}

struct ExportItem: Codable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let description: String
    let brand: String
    let color: String
    let status: String
    let type: String
    let ageGroup: String
    let gender: String
    let condition: String
    let size: String?
    let shoeSize: String?
    let ownerID: UUID?
    let locationID: UUID?
    let listingPrice: Double?
    let donationValue: Double?
    let salePrice: Double?
    let saleDate: Date?
    let donatedDate: Date?
    let photoCount: Int

    init(_ item: ClothingItem) {
        id = item.id
        createdAt = item.createdAt
        updatedAt = item.updatedAt
        description = item.itemDescription
        brand = item.brand
        color = item.color
        status = item.status.rawValue
        type = item.clothingType.rawValue
        ageGroup = item.ageGroup.rawValue
        gender = item.gender.rawValue
        condition = item.condition.rawValue
        size = item.size?.rawValue
        shoeSize = item.shoeSize?.rawValue
        ownerID = item.owner?.id
        locationID = item.location?.id
        listingPrice = item.listingPrice?.doubleValue
        donationValue = item.donationValue?.doubleValue
        salePrice = item.salePrice?.doubleValue
        saleDate = item.saleDate
        donatedDate = item.donatedDate
        photoCount = item.sortedPhotos.count
    }
}

import CoreData
import Foundation

struct CSVExportError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct CSVExporter {
    static let headers = CSVImporter.expectedHeaders

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    /// Builds CSV text for all clothing items, using the same columns as `CSVImporter`.
    static func exportCSV(context: NSManagedObjectContext) throws -> String {
        let items = try fetchItems(context: context)
        guard !items.isEmpty else {
            throw CSVExportError(message: "No items to export. Add clothing to your inventory first.")
        }

        var lines = [headers.joined(separator: ",")]
        for item in items {
            lines.append(row(for: item).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Writes CSV to a temporary file for sharing via the system share sheet.
    static func exportToTemporaryFile(context: NSManagedObjectContext) throws -> URL {
        let csv = try exportCSV(context: context)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let date = formatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("cedar-closet-\(date).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func fetchItems(context: NSManagedObjectContext) throws -> [ClothingItem] {
        let request = ClothingItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClothingItem.updatedAt, ascending: false)]
        return try context.fetch(request)
    }

    private static func row(for item: ClothingItem) -> [String] {
        let location = item.location
        return [
            escape(item.itemDescription),
            escape(item.brand),
            escape(item.color),
            escape(item.size?.rawValue ?? ""),
            escape(item.shoeSize?.rawValue ?? ""),
            escape(item.clothingType.rawValue),
            escape(item.ageGroup.rawValue),
            escape(item.gender.rawValue),
            escape(item.condition.rawValue),
            escape(item.status.rawValue),
            escape(item.owner?.name ?? ""),
            escape(location?.rack ?? ""),
            escape(location?.row ?? ""),
            escape(location?.name ?? ""),
            escape(priceString(item.listingPrice)),
            escape(priceString(item.donationValue)),
            escape(priceString(item.salePrice)),
            escape(dateString(item.saleDate)),
            escape(dateString(item.donatedDate)),
        ]
    }

    private static func dateString(_ date: Date?) -> String {
        guard let date else { return "" }
        return dateFormatter.string(from: date)
    }

    private static func priceString(_ number: NSNumber?) -> String {
        guard let number else { return "" }
        return number.stringValue
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}

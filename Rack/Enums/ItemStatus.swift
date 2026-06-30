import Foundation

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case keep = "Keep"
    case forSale = "For Sale"
    case listed = "Listed"
    case sold = "Sold"
    case forDonation = "For Donation"
    case donated = "Donated"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// Parses stored status strings, including legacy `"Given Away"` values.
    init(storedValue: String) {
        if storedValue == "Given Away" {
            self = .donated
        } else {
            self = ItemStatus(rawValue: storedValue) ?? .keep
        }
    }

    var isForSelling: Bool {
        self == .forSale || self == .listed || self == .sold
    }

    var isForDonating: Bool {
        self == .forDonation || self == .donated
    }
}

import Foundation

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case keep = "Keep"
    case forSale = "For Sale"
    case listed = "Listed"
    case sold = "Sold"
    case forDonation = "For Donation"
    case givenAway = "Given Away"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var isForSelling: Bool {
        self == .forSale || self == .listed || self == .sold
    }

    var isForDonating: Bool {
        self == .forDonation || self == .givenAway
    }
}

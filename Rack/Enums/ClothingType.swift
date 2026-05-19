import Foundation

enum ClothingType: String, Codable, CaseIterable, Identifiable {
    // All ages
    case shirts = "Shirts"
    case jeans = "Jeans"
    case pants = "Pants"
    case shorts = "Shorts"
    case skirt = "Skirt"
    case dress = "Dress"
    case sweater = "Sweater"
    case jacketCoat = "Jacket/Coat"
    // Kids only
    case matchingSet = "Matching Set"
    case onePiece = "One Piece"
    case pajamas = "Pajamas"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var isKidsOnly: Bool {
        self == .matchingSet || self == .onePiece || self == .pajamas
    }

    static func available(for ageGroup: AgeGroup) -> [ClothingType] {
        allCases.filter { ageGroup == .kid || !$0.isKidsOnly }
    }
}

import Foundation

enum SizeCategory: String, CaseIterable {
    case baby = "Baby"
    case toddler = "Toddler"
    case kidsNumeric = "Kids"
    case letter = "Letter"

    static func available(for ageGroup: AgeGroup) -> [SizeCategory] {
        switch ageGroup {
        case .kid: return [.baby, .toddler, .kidsNumeric, .letter]
        case .adult: return [.letter]
        }
    }
}

enum ClothingSize: String, Codable, CaseIterable, Identifiable {
    // Baby (months)
    case newborn = "NB"
    case months0_3 = "0-3M"
    case months3_6 = "3-6M"
    case months6_9 = "6-9M"
    case months9_12 = "9-12M"
    case months12_18 = "12-18M"
    case months18_24 = "18-24M"
    // Toddler
    case t2 = "2T"
    case t3 = "3T"
    case t4 = "4T"
    case t5 = "5T"
    // Kids numeric
    case kids4 = "4"
    case kids5 = "5"
    case kids6 = "6"
    case kids6X = "6X"
    case kids7 = "7"
    case kids8 = "8"
    case kids10 = "10"
    case kids12 = "12"
    case kids14 = "14"
    case kids16 = "16"
    // Letter (big kids + adults)
    case xs = "XS"
    case s = "S"
    case m = "M"
    case l = "L"
    case xl = "XL"
    case xxl = "XXL"
    case xxxl = "XXXL"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var category: SizeCategory {
        switch self {
        case .newborn, .months0_3, .months3_6, .months6_9, .months9_12, .months12_18, .months18_24:
            return .baby
        case .t2, .t3, .t4, .t5:
            return .toddler
        case .kids4, .kids5, .kids6, .kids6X, .kids7, .kids8, .kids10, .kids12, .kids14, .kids16:
            return .kidsNumeric
        case .xs, .s, .m, .l, .xl, .xxl, .xxxl:
            return .letter
        }
    }

    static func available(for ageGroup: AgeGroup) -> [ClothingSize] {
        let categories = SizeCategory.available(for: ageGroup)
        return allCases.filter { categories.contains($0.category) }
    }

    static func grouped(for ageGroup: AgeGroup) -> [(SizeCategory, [ClothingSize])] {
        SizeCategory.available(for: ageGroup).map { category in
            (category, allCases.filter { $0.category == category })
        }
    }
}

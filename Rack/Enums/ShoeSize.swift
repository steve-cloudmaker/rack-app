import Foundation

enum ShoeSizeCategory: String, CaseIterable {
    case babyToddler = "Baby/Toddler"
    case kids = "Kids"
    case womens = "Women's"
    case mens = "Men's"

    static func available(for ageGroup: AgeGroup) -> [ShoeSizeCategory] {
        switch ageGroup {
        case .kid: return [.babyToddler, .kids]
        case .adult: return [.womens, .mens]
        }
    }
}

enum ShoeSize: String, Codable, CaseIterable, Identifiable {
    // Baby/Toddler (crib sizes)
    case c0 = "0C"
    case c1 = "1C"
    case c2 = "2C"
    case c3 = "3C"
    case c4 = "4C"
    case c5 = "5C"
    case c6 = "6C"
    case c7 = "7C"
    case c8 = "8C"
    case c9 = "9C"
    case c10 = "10C"
    // Kids (little kid C → big kid Y)
    case k11 = "11C"
    case k11_5 = "11.5C"
    case k12 = "12C"
    case k12_5 = "12.5C"
    case k13 = "13C"
    case k13_5 = "13.5C"
    case y1 = "1Y"
    case y1_5 = "1.5Y"
    case y2 = "2Y"
    case y2_5 = "2.5Y"
    case y3 = "3Y"
    case y3_5 = "3.5Y"
    case y4 = "4Y"
    case y4_5 = "4.5Y"
    case y5 = "5Y"
    case y5_5 = "5.5Y"
    case y6 = "6Y"
    case y6_5 = "6.5Y"
    case y7 = "7Y"
    // Women's
    case w5 = "5W"
    case w5_5 = "5.5W"
    case w6 = "6W"
    case w6_5 = "6.5W"
    case w7 = "7W"
    case w7_5 = "7.5W"
    case w8 = "8W"
    case w8_5 = "8.5W"
    case w9 = "9W"
    case w9_5 = "9.5W"
    case w10 = "10W"
    case w10_5 = "10.5W"
    case w11 = "11W"
    case w11_5 = "11.5W"
    case w12 = "12W"
    // Men's
    case m6 = "6M"
    case m6_5 = "6.5M"
    case m7 = "7M"
    case m7_5 = "7.5M"
    case m8 = "8M"
    case m8_5 = "8.5M"
    case m9 = "9M"
    case m9_5 = "9.5M"
    case m10 = "10M"
    case m10_5 = "10.5M"
    case m11 = "11M"
    case m11_5 = "11.5M"
    case m12 = "12M"
    case m12_5 = "12.5M"
    case m13 = "13M"
    case m14 = "14M"
    case m15 = "15M"

    var id: String { rawValue }

    var category: ShoeSizeCategory {
        switch self {
        case .c0, .c1, .c2, .c3, .c4, .c5, .c6, .c7, .c8, .c9, .c10:
            return .babyToddler
        case .k11, .k11_5, .k12, .k12_5, .k13, .k13_5,
             .y1, .y1_5, .y2, .y2_5, .y3, .y3_5, .y4, .y4_5, .y5, .y5_5, .y6, .y6_5, .y7:
            return .kids
        case .w5, .w5_5, .w6, .w6_5, .w7, .w7_5, .w8, .w8_5, .w9, .w9_5, .w10, .w10_5, .w11, .w11_5, .w12:
            return .womens
        case .m6, .m6_5, .m7, .m7_5, .m8, .m8_5, .m9, .m9_5, .m10, .m10_5, .m11, .m11_5, .m12, .m12_5, .m13, .m14, .m15:
            return .mens
        }
    }

    // Short form for use inside a grouped picker where the section header provides context.
    var displayName: String {
        switch category {
        case .womens, .mens: return String(rawValue.dropLast())
        case .babyToddler, .kids: return rawValue
        }
    }

    // Unambiguous form for list rows, AI prompts, and any context without a category header.
    var contextualDisplayName: String {
        switch category {
        case .womens: return "Women's \(String(rawValue.dropLast()))"
        case .mens: return "Men's \(String(rawValue.dropLast()))"
        case .babyToddler, .kids: return rawValue
        }
    }

    static func available(for ageGroup: AgeGroup) -> [ShoeSize] {
        let categories = ShoeSizeCategory.available(for: ageGroup)
        return allCases.filter { categories.contains($0.category) }
    }

    static func grouped(for ageGroup: AgeGroup) -> [(ShoeSizeCategory, [ShoeSize])] {
        ShoeSizeCategory.available(for: ageGroup).map { cat in
            (cat, allCases.filter { $0.category == cat })
        }
    }
}

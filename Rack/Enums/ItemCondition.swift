import Foundation

enum ItemCondition: String, Codable, CaseIterable, Identifiable {
    case newWithTags = "New with Tags"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

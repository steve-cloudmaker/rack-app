import Foundation

enum AgeGroup: String, Codable, CaseIterable, Identifiable {
    case adult = "Adult"
    case kid = "Kid"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

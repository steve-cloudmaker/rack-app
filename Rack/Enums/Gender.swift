import Foundation

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case unisex = "Unisex"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

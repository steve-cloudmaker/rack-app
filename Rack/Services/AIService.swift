import Foundation

actor AIService {
    static let shared = AIService()
    private let apiKeyStorageKey = "anthropic_api_key"

    private var apiKey: String {
        UserDefaults.standard.string(forKey: apiKeyStorageKey) ?? ""
    }

    private var isConfigured: Bool { !apiKey.isEmpty }

    func generateDescription(photoData: [Data]) async -> String? {
        guard isConfigured else { return nil }
        // TODO: Implement Claude vision API call to generate clothing description from photos
        return nil
    }

    func estimatePrice(item: ClothingItem) async -> Double? {
        guard isConfigured else { return nil }
        // TODO: Implement Claude API call to estimate resale price based on brand, condition, size, type
        return nil
    }
}

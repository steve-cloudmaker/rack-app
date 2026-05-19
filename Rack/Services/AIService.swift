import Foundation

actor AIService {
    static let shared = AIService()

    private let apiKeyStorageKey = "anthropic_api_key"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5-20251001"

    private var apiKey: String {
        UserDefaults.standard.string(forKey: apiKeyStorageKey) ?? ""
    }

    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Public API

    func generateDescription(photoData: [Data]) async -> String? {
        guard isConfigured, !photoData.isEmpty else { return nil }

        let imageBlocks: [ContentBlock] = photoData.prefix(3).map { data in
            .image(mediaType: mediaType(for: data), data: data.base64EncodedString())
        }
        let textBlock = ContentBlock.text(
            "Describe this clothing item in one concise sentence (10–15 words) for a resale inventory. " +
            "Include the item type, primary color, and brand if clearly visible. " +
            "Do not include size or condition. Respond with only the description sentence."
        )

        let request = MessagesRequest(
            model: model,
            maxTokens: 100,
            system: "You are a clothing resale assistant helping catalog items for Poshmark and similar platforms.",
            messages: [Message(role: "user", content: imageBlocks + [textBlock])]
        )

        return await send(request)
    }

    func estimatePrice(
        brand: String,
        type: ClothingType,
        condition: ItemCondition,
        size: ClothingSize?,
        ageGroup: AgeGroup
    ) async -> Double? {
        guard isConfigured else { return nil }

        let details = [
            "Type: \(type.displayName)",
            "Brand: \(brand.isEmpty ? "Unknown" : brand)",
            "Condition: \(condition.displayName)",
            "Size: \(size?.displayName ?? "Unknown")",
            "Age group: \(ageGroup.displayName)"
        ].joined(separator: "\n")

        let prompt =
            "Suggest a Poshmark listing price in USD for this clothing item:\n\(details)\n\n" +
            "Respond with only the dollar amount as a whole number. Example: 15"

        let request = MessagesRequest(
            model: model,
            maxTokens: 10,
            system: "You are an expert Poshmark seller with deep knowledge of current resale market values.",
            messages: [Message(role: "user", content: [.text(prompt)])]
        )

        guard let text = await send(request) else { return nil }
        return Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Networking

    private func send(_ requestBody: MessagesRequest) async -> String? {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")

        let encoder = JSONEncoder()
        guard let body = try? encoder.encode(requestBody) else { return nil }
        urlRequest.httpBody = body

        guard let (data, response) = try? await URLSession.shared.data(for: urlRequest),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

        guard let decoded = try? JSONDecoder().decode(MessagesResponse.self, from: data) else { return nil }
        return decoded.content.first(where: { $0.type == "text" })?.text
    }

    // MARK: - Helpers

    private func mediaType(for data: Data) -> String {
        guard data.count >= 4 else { return "image/jpeg" }
        let bytes = [UInt8](data.prefix(4))
        if bytes[0] == 0x89 && bytes[1] == 0x50 { return "image/png" }
        if bytes[0] == 0xFF && bytes[1] == 0xD8 { return "image/jpeg" }
        if bytes[0] == 0x52 && bytes[1] == 0x49 { return "image/webp" }
        return "image/jpeg"
    }
}

// MARK: - Request / Response Types

private struct MessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model, system, messages
        case maxTokens = "max_tokens"
    }
}

private struct Message: Encodable {
    let role: String
    let content: [ContentBlock]
}

private enum ContentBlock: Encodable {
    case text(String)
    case image(mediaType: String, data: String)

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CK.self)
        switch self {
        case .text(let str):
            try c.encode("text", forKey: .type)
            try c.encode(str, forKey: .text)
        case .image(let mt, let b64):
            try c.encode("image", forKey: .type)
            var src = c.nestedContainer(keyedBy: SK.self, forKey: .source)
            try src.encode("base64", forKey: .type)
            try src.encode(mt, forKey: .mediaType)
            try src.encode(b64, forKey: .data)
        }
    }

    enum CK: String, CodingKey { case type, text, source }
    enum SK: String, CodingKey {
        case type, data
        case mediaType = "media_type"
    }
}

private struct MessagesResponse: Decodable {
    let content: [ResponseContent]
}

private struct ResponseContent: Decodable {
    let type: String
    let text: String?
}

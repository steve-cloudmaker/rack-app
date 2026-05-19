import Foundation
import UIKit

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

        let imageBlocks: [ContentBlock] = photoData.prefix(3).compactMap { data in
            guard let (prepared, mt) = prepareImage(data) else { return nil }
            return .image(mediaType: mt, data: prepared.base64EncodedString())
        }
        guard !imageBlocks.isEmpty else {
            print("[AIService] No images could be prepared for API")
            return nil
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
        shoeSize: ShoeSize?,
        ageGroup: AgeGroup
    ) async -> Double? {
        guard isConfigured else { return nil }

        let sizeDisplay = type == .shoes ? (shoeSize?.contextualDisplayName ?? "Unknown") : (size?.displayName ?? "Unknown")
        let details = [
            "Type: \(type.displayName)",
            "Brand: \(brand.isEmpty ? "Unknown" : brand)",
            "Condition: \(condition.displayName)",
            "Size: \(sizeDisplay)",
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
        do {
            let body = try encoder.encode(requestBody)
            print("[AIService] Sending request — body: \(body.count / 1024) KB")
            urlRequest.httpBody = body
        } catch {
            print("[AIService] Encoding failed: \(error)")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[AIService] Response status: \(status)")
            guard status == 200 else {
                print("[AIService] Error body: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
                return nil
            }
            let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
            return decoded.content.first(where: { $0.type == "text" })?.text
        } catch {
            print("[AIService] Request failed: \(error)")
            return nil
        }
    }

    // MARK: - Image Preparation

    // Transcodes to JPEG and resizes to fit within maxDimension.
    // Handles HEIC and any other format UIImage can decode.
    private func prepareImage(_ data: Data, maxDimension: CGFloat = 1568) -> (Data, String)? {
        guard let image = UIImage(data: data) else {
            print("[AIService] Could not decode image data (\(data.count) bytes)")
            return nil
        }
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1.0
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }

        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else {
            print("[AIService] JPEG conversion failed")
            return nil
        }
        print("[AIService] Image prepared: \(Int(targetSize.width))×\(Int(targetSize.height)), \(jpeg.count / 1024) KB")
        return (jpeg, "image/jpeg")
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

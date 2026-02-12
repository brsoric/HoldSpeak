import Foundation
import os

private let logger = Logger(subsystem: "com.holdspeak.app", category: "GeminiClient")

public struct GeminiClient: Sendable {
    public enum ClientError: Error, LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int, body: String?)
        case decodeError
        case noTextInResponse

        public var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid response from Gemini API"
            case .httpError(let code, let body): return "Gemini API error \(code): \(body ?? "unknown")"
            case .decodeError: return "Failed to decode Gemini response"
            case .noTextInResponse: return "No text in Gemini response"
            }
        }
    }

    public let apiKey: String

    // swiftlint:disable:next force_unwrapping
    private static let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Generate Content

    public func generateContent(text: String, systemInstruction: String, model: String) async throws -> String {
        let url = Self.baseURL.appendingPathComponent("models/\(model):generateContent")

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ClientError.invalidResponse
        }
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let requestURL = components.url else { throw ClientError.invalidResponse }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": text]]]
            ],
            "systemInstruction": [
                "parts": [["text": systemInstruction]]
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let json = try await send(request)

        guard let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String,
              !text.isEmpty
        else {
            throw ClientError.noTextInResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - List Models

    public func listModels() async throws -> [GeminiModelInfo] {
        guard var components = URLComponents(
            url: Self.baseURL.appendingPathComponent("models"),
            resolvingAgainstBaseURL: false
        ) else {
            throw ClientError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "pageSize", value: "100"),
        ]

        guard let requestURL = components.url else { throw ClientError.invalidResponse }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"

        let json = try await send(request)

        guard let models = json["models"] as? [[String: Any]] else {
            throw ClientError.decodeError
        }

        return models.compactMap { dict -> GeminiModelInfo? in
            guard let name = dict["name"] as? String,
                  let displayName = dict["displayName"] as? String,
                  let methods = dict["supportedGenerationMethods"] as? [String]
            else { return nil }
            return GeminiModelInfo(name: name, displayName: displayName, supportedMethods: methods)
        }
    }

    // MARK: - Private

    private func send(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }

        if !(200...299).contains(http.statusCode) {
            let bodyText = String(data: data, encoding: .utf8)
            throw ClientError.httpError(statusCode: http.statusCode, body: bodyText)
        }

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ClientError.decodeError
            }
            return json
        } catch is ClientError {
            throw ClientError.decodeError
        } catch {
            logger.error("JSON parse failed: \(error.localizedDescription, privacy: .public)")
            throw ClientError.decodeError
        }
    }
}

// MARK: - Model Info

public struct GeminiModelInfo: Sendable {
    public let name: String
    public let displayName: String
    public let supportedMethods: [String]

    /// Short model ID for API calls (strips "models/" prefix).
    public var modelId: String {
        name.hasPrefix("models/") ? String(name.dropFirst(7)) : name
    }

    public var supportsGeneration: Bool {
        supportedMethods.contains("generateContent")
    }
}

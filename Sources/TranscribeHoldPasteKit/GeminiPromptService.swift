import Foundation

/// Prompt transformation using Google Gemini API.
/// Wraps GeminiClient behind the PromptService protocol.
public struct GeminiPromptService: PromptService {
    private let client: GeminiClient
    private let model: String

    public var isAvailable: Bool { true }

    public init(client: GeminiClient, model: String = "gemini-2.0-flash") {
        self.client = client
        self.model = model
    }

    public func transform(text: String, prompt: String) async throws -> String {
        try await client.generateContent(text: text, systemInstruction: prompt, model: model)
    }
}

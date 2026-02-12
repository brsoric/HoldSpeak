import Foundation

/// Prompt transformation using OpenAI API.
/// Wraps existing OpenAIClient behind the PromptService protocol.
public struct OpenAIPromptService: PromptService {
    private let client: OpenAIClient
    private let model: String

    public var isAvailable: Bool { true }

    public init(client: OpenAIClient, model: String = "gpt-4.1-nano") {
        self.client = client
        self.model = model
    }

    public func transform(text: String, prompt: String) async throws -> String {
        try await client.promptTransform(text: text, prompt: prompt, model: model)
    }
}

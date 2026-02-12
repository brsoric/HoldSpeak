import Foundation

/// Protocol for text transformation/rewriting services.
/// Conform to this protocol to provide a text transformation backend.
public protocol PromptService: Sendable {
    /// Transform text using a prompt instruction.
    /// - Parameters:
    ///   - text: The raw text to transform
    ///   - prompt: The instruction for how to transform the text
    /// - Returns: Transformed text
    func transform(text: String, prompt: String) async throws -> String

    /// Whether the service is available (e.g., API key configured, network reachable).
    var isAvailable: Bool { get }
}

/// Supported AI providers for text transformation.
public enum AIProvider: String, CaseIterable, Sendable {
    case openai = "openai"
    case gemini = "gemini"

    public var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .gemini: return "Gemini"
        }
    }

    public var keychainAccount: String {
        switch self {
        case .openai: return "openai_api_key"
        case .gemini: return "gemini_api_key"
        }
    }
}

import Foundation

/// Remote transcription using OpenAI API (legacy/fallback).
/// Wraps existing OpenAIClient behind the TranscriptionService protocol.
public struct OpenAITranscriber: TranscriptionService {
    private let client: OpenAIClient
    private let model: String

    public var isReady: Bool { true }
    public let displayName = "OpenAI API"

    public init(client: OpenAIClient, model: String = "gpt-4o-mini-transcribe") {
        self.client = client
        self.model = model
    }

    public func transcribe(fileURL: URL, language: String?, translateToEnglish: Bool = false) async throws -> String {
        // OpenAI API transcription does not support local translate task; ignored here
        try await client.transcribe(fileURL: fileURL, model: model, language: language)
    }
}

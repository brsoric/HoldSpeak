import Foundation

/// Protocol for speech-to-text engines.
/// Conform to this protocol to provide a transcription backend (local or remote).
public protocol TranscriptionService: Sendable {
    /// Transcribe audio file to text.
    /// - Parameters:
    ///   - fileURL: Path to audio file (M4A)
    ///   - language: Optional language hint (nil = auto-detect)
    ///   - translateToEnglish: When true, use Whisper's built-in translate task (outputs English)
    /// - Returns: Transcribed text
    func transcribe(fileURL: URL, language: String?, translateToEnglish: Bool) async throws -> String

    /// Whether the service is ready to transcribe.
    var isReady: Bool { get }

    /// Human-readable name for UI display.
    var displayName: String { get }
}

/// Errors specific to transcription services.
public enum TranscriberError: Error, LocalizedError {
    case modelNotLoaded
    case transcriptionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Transcription model is not loaded. Please wait for model loading to complete."
        case .transcriptionFailed(let detail):
            return "Transcription failed: \(detail)"
        }
    }
}

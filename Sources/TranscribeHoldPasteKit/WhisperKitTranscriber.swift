import Foundation
@preconcurrency import WhisperKit

/// Local transcription using WhisperKit with bundled CoreML model.
public final class WhisperKitTranscriber: TranscriptionService, @unchecked Sendable {
    private var whisperKit: WhisperKit?
    private let modelName: String
    private let lock = NSLock()

    public var isReady: Bool {
        lock.lock()
        defer { lock.unlock() }
        return whisperKit != nil
    }

    public let displayName = "WhisperKit (Local)"

    public init(modelName: String = "openai_whisper-small") {
        self.modelName = modelName
    }

    private func storeKit(_ kit: WhisperKit) {
        lock.lock()
        whisperKit = kit
        lock.unlock()
    }

    private func currentKit() -> WhisperKit? {
        lock.lock()
        defer { lock.unlock() }
        return whisperKit
    }

    /// Pre-load model on app start. Call from a background Task.
    /// Looks for the model in the app bundle's Resources directory first,
    /// then falls back to WhisperKit's default download behavior.
    public func loadModel() async throws {
        let modelPath: String?
        if let resourcePath = Bundle.main.resourcePath {
            let bundledPath = (resourcePath as NSString).appendingPathComponent(modelName)
            if FileManager.default.fileExists(atPath: bundledPath) {
                modelPath = resourcePath
            } else {
                modelPath = nil
            }
        } else {
            modelPath = nil
        }

        let kit: WhisperKit
        if let modelPath {
            kit = try await WhisperKit(
                modelFolder: modelPath + "/" + modelName,
                verbose: false,
                prewarm: true
            )
        } else {
            kit = try await WhisperKit(
                model: modelName,
                verbose: false,
                prewarm: true
            )
        }

        storeKit(kit)
    }

    public func transcribe(fileURL: URL, language: String?, translateToEnglish: Bool = false) async throws -> String {
        guard let kit = currentKit() else {
            throw TranscriberError.modelNotLoaded
        }

        let options = DecodingOptions(
            task: translateToEnglish ? .translate : .transcribe,
            language: language,
            temperatureFallbackCount: 3,
            sampleLength: 224,
            usePrefillPrompt: language != nil,
            skipSpecialTokens: true,
            withoutTimestamps: true
        )

        let results = try await kit.transcribe(audioPath: fileURL.path, decodeOptions: options)
        let text = results
            .map { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            throw TranscriberError.transcriptionFailed("Empty transcription result")
        }

        return text
    }
}

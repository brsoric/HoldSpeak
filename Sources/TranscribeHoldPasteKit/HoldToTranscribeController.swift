import Foundation

public final class HoldToTranscribeController: @unchecked Sendable {
    public enum State: Sendable, Equatable {
        case idle
        case recording
        case transcribing
        case failed(message: String)
    }

    public struct Config: Sendable {
        public var model: String
        public var language: String?
        public var translationLanguage: String?
        public var restoreClipboardDelaySeconds: TimeInterval
        public var promptModel: String
        public var promptTemplate: String
        public var maxRecordingSeconds: TimeInterval

        public init(
            model: String = "gpt-4o-mini-transcribe",
            language: String? = nil,
            translationLanguage: String? = nil,
            restoreClipboardDelaySeconds: TimeInterval = 0.3,
            promptModel: String = "gpt-4o-mini",
            promptTemplate: String = "Rewrite the text to be clear and concise. Keep the meaning. Output only the rewritten text.",
            maxRecordingSeconds: TimeInterval = 600
        ) {
            self.model = model
            self.language = language
            self.translationLanguage = translationLanguage
            self.restoreClipboardDelaySeconds = restoreClipboardDelaySeconds
            self.promptModel = promptModel
            self.promptTemplate = promptTemplate
            self.maxRecordingSeconds = maxRecordingSeconds
        }
    }

    public enum Behavior: Sendable, Equatable {
        case pasteTranscript
        case pastePrompted
    }

    public struct Result: Sendable {
        public var behavior: Behavior
        public var transcript: String?
        public var finalText: String?
        public var didPaste: Bool
        public var didCopyToClipboard: Bool
        public var errorMessage: String?

        public init(
            behavior: Behavior,
            transcript: String?,
            finalText: String?,
            didPaste: Bool,
            didCopyToClipboard: Bool,
            errorMessage: String?
        ) {
            self.behavior = behavior
            self.transcript = transcript
            self.finalText = finalText
            self.didPaste = didPaste
            self.didCopyToClipboard = didCopyToClipboard
            self.errorMessage = errorMessage
        }
    }

    private let recorder: AudioHoldRecorder
    private let transcriber: any TranscriptionService
    private let promptService: (any PromptService)?
    private let translationService: (any PromptService)?
    private let inserter: ClipboardInserter
    private let config: Config

    private let lock = NSLock()
    private var _transcriptionTask: Task<Void, Never>?
    private var _stateHandler: (@Sendable (State) -> Void)?
    private var _resultHandler: (@Sendable (Result) -> Void)?
    private var _pendingBehavior: Behavior = .pasteTranscript
    private var _maxDurationStop: DispatchWorkItem?
    private var _capturedContext: String?

    private var transcriptionTask: Task<Void, Never>? {
        get { lock.lock(); defer { lock.unlock() }; return _transcriptionTask }
        set { lock.lock(); defer { lock.unlock() }; _transcriptionTask = newValue }
    }
    private var stateHandler: (@Sendable (State) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _stateHandler }
        set { lock.lock(); defer { lock.unlock() }; _stateHandler = newValue }
    }
    private var resultHandler: (@Sendable (Result) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _resultHandler }
        set { lock.lock(); defer { lock.unlock() }; _resultHandler = newValue }
    }
    private var pendingBehavior: Behavior {
        get { lock.lock(); defer { lock.unlock() }; return _pendingBehavior }
        set { lock.lock(); defer { lock.unlock() }; _pendingBehavior = newValue }
    }
    private var maxDurationStop: DispatchWorkItem? {
        get { lock.lock(); defer { lock.unlock() }; return _maxDurationStop }
        set { lock.lock(); defer { lock.unlock() }; _maxDurationStop = newValue }
    }
    private var capturedContext: String? {
        get { lock.lock(); defer { lock.unlock() }; return _capturedContext }
        set { lock.lock(); defer { lock.unlock() }; _capturedContext = newValue }
    }

    public init(
        recorder: AudioHoldRecorder = AudioHoldRecorder(),
        transcriber: any TranscriptionService,
        promptService: (any PromptService)? = nil,
        translationService: (any PromptService)? = nil,
        inserter: ClipboardInserter = ClipboardInserter(),
        config: Config = Config()
    ) {
        self.recorder = recorder
        self.transcriber = transcriber
        self.promptService = promptService
        self.translationService = translationService
        self.inserter = inserter
        self.config = config
    }

    public func setStateHandler(_ handler: (@Sendable (State) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        _stateHandler = handler
    }

    public func setResultHandler(_ handler: (@Sendable (Result) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        _resultHandler = handler
    }

    public func setAmplitudeHandler(_ handler: ((Float) -> Void)?) {
        recorder.amplitudeHandler = handler
    }

    public func handleHotkeyPressed(behavior: Behavior = .pasteTranscript) {
        transcriptionTask?.cancel()
        maxDurationStop?.cancel()
        pendingBehavior = behavior

        // Capture selected text if this is AI rewrite mode
        if behavior == .pastePrompted {
            // Call synchronously - AX APIs are thread-safe
            let captured = TextSelectionCapture.captureSelectedText()
            capturedContext = captured
            if let ctx = captured {
                print("✅ Context captured: \"\(ctx.prefix(100))...\" (\(ctx.count) chars)")
            } else {
                print("ℹ️ No context captured (no selection or capture failed)")
            }
        } else {
            capturedContext = nil
        }

        do {
            try recorder.start()
            stateHandler?(.recording)

            let item = DispatchWorkItem { [weak self] in
                guard let self else { return }
                guard self.recorder.isRecording else { return }
                self.handleHotkeyReleased()
            }
            maxDurationStop = item
            DispatchQueue.main.asyncAfter(deadline: .now() + config.maxRecordingSeconds, execute: item)
        } catch {
            stateHandler?(.failed(message: "Failed to start recording: \(error)"))
            resultHandler?(
                Result(
                    behavior: behavior,
                    transcript: nil,
                    finalText: nil,
                    didPaste: false,
                    didCopyToClipboard: false,
                    errorMessage: "Failed to start recording: \(error)"
                )
            )
        }
    }

    public func handleHotkeyReleased() {
        maxDurationStop?.cancel()

        let fileURL: URL
        do {
            fileURL = try recorder.stop()
        } catch {
            if let recorderError = error as? AudioHoldRecorder.RecorderError, recorderError == .notRecording {
                // Happens if we auto-stopped at max duration but the user releases later.
                return
            }
            stateHandler?(.failed(message: "Failed to stop recording: \(error)"))
            resultHandler?(
                Result(
                    behavior: pendingBehavior,
                    transcript: nil,
                    finalText: nil,
                    didPaste: false,
                    didCopyToClipboard: false,
                    errorMessage: "Failed to stop recording: \(error)"
                )
            )
            return
        }

        stateHandler?(.transcribing)

        let language = config.language
        let translationLanguage = config.translationLanguage
        let restoreDelay = config.restoreClipboardDelaySeconds
        let behavior = pendingBehavior
        let promptTemplate = config.promptTemplate
        let transcriber = self.transcriber
        let promptService = self.promptService
        let translationService = self.translationService

        transcriptionTask = Task { [inserter, stateHandler, resultHandler] in
            do {
                defer { try? FileManager.default.removeItem(at: fileURL) }
                // Use Whisper's built-in translate task for English; otherwise transcribe normally
                let useWhisperTranslate = translationLanguage == "en"
                var text = try await transcriber.transcribe(
                    fileURL: fileURL,
                    language: language,
                    translateToEnglish: useWhisperTranslate
                )

                // For non-English translation targets, use AI service
                if let targetLang = translationLanguage, targetLang != "en" {
                    let svc = translationService ?? promptService
                    if let svc, svc.isAvailable {
                        let langName = Self.languageDisplayName(targetLang)
                        let translatePrompt = "You are a professional translator. Translate the following text to \(langName). Preserve the original meaning and tone. Output ONLY the translated text, nothing else."
                        text = try await svc.transform(text: text, prompt: translatePrompt)
                    } else {
                        stateHandler?(.failed(message: "Set API key in Settings for translation"))
                    }
                }

                let finalText: String
                var usedContext = false
                switch behavior {
                case .pasteTranscript:
                    finalText = text
                case .pastePrompted:
                    if let promptService, promptService.isAvailable {
                        // Check if we captured selected text as context
                        let context = capturedContext
                        capturedContext = nil // Reset immediately after reading

                        let (inputText, systemPrompt): (String, String)
                        if let context = context, !context.isEmpty {
                            // Context mode: user instruction + selected text
                            usedContext = true
                            print("🎯 Using CONTEXT MODE")
                            print("📝 Selected text: \"\(context.prefix(50))...\"")
                            print("🗣️ User instruction: \"\(text)\"")

                            systemPrompt = """
                            You are an AI editing assistant. The user has selected text and spoken an instruction.
                            Apply the instruction to the selected text and output only the result.
                            """
                            inputText = """
                            SELECTED TEXT:
                            \(context)

                            USER INSTRUCTION:
                            \(text)
                            """
                        } else {
                            // Original mode: rewrite the transcription
                            print("📄 Using ORIGINAL MODE (no context)")
                            print("🗣️ Transcription: \"\(text)\"")

                            systemPrompt = promptTemplate
                            inputText = text
                        }

                        finalText = try await promptService.transform(text: inputText, prompt: systemPrompt)
                    } else {
                        finalText = text
                        stateHandler?(.failed(message: "Set API key in Settings for AI rewriting"))
                    }
                }

                // Smart paste behavior: copy to clipboard if context was used (to avoid replacing selected text)
                do {
                    if usedContext {
                        // Context mode: Copy to clipboard to avoid replacing the selected text
                        print("📋 Copying to clipboard (context mode - won't replace selection)")
                        try inserter.copyToClipboard(text: finalText)
                        stateHandler?(.idle)
                        resultHandler?(
                            Result(
                                behavior: behavior,
                                transcript: text,
                                finalText: finalText,
                                didPaste: false,
                                didCopyToClipboard: true,
                                errorMessage: nil
                            )
                        )
                        stateHandler?(.failed(message: "Result copied to clipboard. Paste where you want (⌘V)"))
                    } else {
                        // Normal mode: Paste as usual
                        try inserter.insertByPasting(text: finalText, restoreAfter: restoreDelay)
                        stateHandler?(.idle)
                        resultHandler?(
                            Result(
                                behavior: behavior,
                                transcript: text,
                                finalText: finalText,
                                didPaste: true,
                                didCopyToClipboard: false,
                                errorMessage: nil
                            )
                        )
                    }
                } catch {
                    // Fallback: at least put the result on the clipboard.
                    try? inserter.copyToClipboard(text: finalText)
                    let message: String
                    if let insertError = error as? ClipboardInserter.InsertError, insertError == .accessibilityNotTrusted {
                        message = "Grant Accessibility permission (to paste). Copied to clipboard."
                    } else {
                        message = "Could not paste. Copied to clipboard."
                    }
                    stateHandler?(.failed(message: message))
                    resultHandler?(
                        Result(
                            behavior: behavior,
                            transcript: text,
                            finalText: finalText,
                            didPaste: false,
                            didCopyToClipboard: true,
                            errorMessage: "Could not paste: \(error)"
                        )
                    )
                }
            } catch is CancellationError {
                stateHandler?(.idle)
            } catch {
                stateHandler?(.failed(message: "Transcription failed: \(error)"))
                resultHandler?(
                    Result(
                        behavior: behavior,
                        transcript: nil,
                        finalText: nil,
                        didPaste: false,
                        didCopyToClipboard: false,
                        errorMessage: "Transcription failed: \(error)"
                    )
                )
            }
        }
    }

    private static func languageDisplayName(_ code: String) -> String {
        switch code {
        case "en": return "English"
        case "pt": return "Portuguese"
        case "de": return "German"
        case "lb": return "Luxembourgish"
        case "ru": return "Russian"
        case "uk": return "Ukrainian"
        case "ja": return "Japanese"
        case "zh": return "Chinese"
        default: return code
        }
    }
}

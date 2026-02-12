import AppKit
import Foundation
import os
import TranscribeHoldPasteKit

private let logger = Logger(subsystem: "com.holdspeak.app", category: "AppModel")

@MainActor
final class AppModel: ObservableObject {
    struct TranscriptHistoryItem: Codable, Identifiable, Equatable {
        enum Mode: String, Codable {
            case transcript
            case prompted
        }

        var id: String
        var date: Date
        var mode: Mode
        var transcript: String?
        var finalText: String?
        var didPaste: Bool
        var didCopyToClipboard: Bool
        var errorMessage: String?
    }

    enum ModelState: Equatable {
        case loading
        case ready
        case error(String)
    }

    @Published var statusLine: String = "Loading model..."
    @Published var isListeningEnabled: Bool = false
    @Published var modelState: ModelState = .loading

    @Published var aiProvider: AIProvider = .openai
    @Published var availableModels: [String] = []
    @Published var isLoadingModels: Bool = false
    @Published var modelLoadError: String?
    @Published var geminiApiKeyIsSet: Bool = false
    @Published var geminiApiKeyLength: Int = 0
    @Published var promptModelName: String = "gpt-4o-mini"
    @Published var promptTemplate: String = "Rewrite the text to be clear and concise. Keep the meaning. Output only the rewritten text."
    @Published var preferredLanguage: String? = nil {
        didSet { autoRestartListeningIfNeeded() }
    }
    @Published var translationLanguage: String? = nil {
        didSet { autoRestartListeningIfNeeded() }
    }
    @Published var useToggleMode: Bool = false {
        didSet { autoRestartListeningIfNeeded() }
    }
    @Published var apiKeyIsSet: Bool = false
    @Published var apiKeyLength: Int = 0
    @Published var microphoneState: Permissions.MicrophoneState = .notDetermined
    @Published var accessibilityTrusted: Bool = false
    @Published var inputMonitoringAllowed: Bool = false
    @Published var hotkeyRegistered: Bool = false
    @Published var hotkeyLastError: String?
    @Published var settingsFeedback: String?
    @Published var settingsFeedbackIsError: Bool = false
    @Published var lastHotkeyEventAt: Date?
    @Published var transcriptHistory: [TranscriptHistoryItem] = []
    @Published var hotkeyConfig: HotkeyConfig = HotkeyConfig.load()
    @Published var amplitudes: [CGFloat] = Array(repeating: 0, count: AppModel.amplitudeBarCount)
    @Published private(set) var isRecording: Bool = false

    var dsModelState: HSModelState {
        switch modelState {
        case .loading: return .loading
        case .ready: return .ready
        case .error(let msg): return .error(msg)
        }
    }

    // MARK: - Constants

    private enum Keys {
        static let promptTemplate = "prompt_template"
        static let promptModel = "prompt_model"
        static let preferredLanguage = "preferred_language"
        static let translationLanguage = "translation_language"
        static let history = "transcript_history_v1"
        static let apiKeyAccount = "openai_api_key"
        static let useToggleMode = "use_toggle_mode"
        static let aiProvider = "ai_provider"
    }

    private static let maxHistoryCount = 10
    static let amplitudeBarCount = 28
    private static let pulseInterval: TimeInterval = 0.6
    private static let feedbackDismissDelay: TimeInterval = 2.0

    // MARK: - Dependencies

    private let keychain = KeychainStore(service: "HoldSpeak")
    private let legacyKeychain = KeychainStore(service: "TranscribeHoldPaste")
    private let whisperTranscriber = WhisperKitTranscriber()
    private var controller: HoldToTranscribeController?
    private var monitorRaw: PressAndHoldHotkeyMonitor?
    private var monitorPrompt: PressAndHoldHotkeyMonitor?
    private var settingsWindow: SettingsWindowController?
    private var toast: ToastWindowController?

    private enum Activity {
        case idle
        case loading
        case recording
        case transcribing
    }

    private var activity: Activity = .loading
    private var pulseTimer: Timer?
    private var didFinishInit = false
    @Published private(set) var pulseTick: Bool = false

    init() {
        if let providerRaw = UserDefaults.standard.string(forKey: Keys.aiProvider),
           let provider = AIProvider(rawValue: providerRaw) {
            aiProvider = provider
        }
        // Keychain and permissions are NOT checked here — only on demand
        // (permissions via Settings tab, keychain via AI Rewriting tab)
        promptTemplate = UserDefaults.standard.string(forKey: Keys.promptTemplate) ?? promptTemplate
        promptModelName = UserDefaults.standard.string(forKey: Keys.promptModel) ?? promptModelName
        preferredLanguage = UserDefaults.standard.string(forKey: Keys.preferredLanguage)
        translationLanguage = UserDefaults.standard.string(forKey: Keys.translationLanguage)
        useToggleMode = UserDefaults.standard.bool(forKey: Keys.useToggleMode)
        loadHistory()
        didFinishInit = true

        Task { await loadWhisperModel() }
    }

    private func loadWhisperModel() async {
        modelState = .loading
        activity = .loading
        statusLine = "Loading WhisperKit model..."
        startPulsingIfNeeded()

        do {
            try await whisperTranscriber.loadModel()
            modelState = .ready
            activity = .idle
            statusLine = "Ready (Ctrl+Opt+Space to transcribe)"
            stopPulsing()
        } catch {
            modelState = .error(error.localizedDescription)
            activity = .idle
            statusLine = "Model failed to load"
            stopPulsing()
            showToast("WhisperKit model failed to load. Restart the app.", variant: .error)
        }
    }

    func showSettingsWindow() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(appModel: self)
        }
        settingsWindow?.show()
    }

    private func getAPIKey(for provider: AIProvider) -> String {
        let value: String?
        switch provider {
        case .openai:
            value = (try? keychain.getString(account: provider.keychainAccount))
                ?? (try? legacyKeychain.getString(account: provider.keychainAccount))
        case .gemini:
            value = try? keychain.getString(account: provider.keychainAccount)
        }
        return (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func refreshKeychainState() {
        let openAIKey = getAPIKey(for: .openai)
        apiKeyIsSet = !openAIKey.isEmpty
        apiKeyLength = openAIKey.count

        let geminiKey = getAPIKey(for: .gemini)
        geminiApiKeyIsSet = !geminiKey.isEmpty
        geminiApiKeyLength = geminiKey.count
    }

    var currentProviderKeyIsSet: Bool {
        switch aiProvider {
        case .openai: return apiKeyIsSet
        case .gemini: return geminiApiKeyIsSet
        }
    }

    var currentProviderKeyLength: Int {
        switch aiProvider {
        case .openai: return apiKeyLength
        case .gemini: return geminiApiKeyLength
        }
    }

    func fetchAvailableModels() {
        isLoadingModels = true
        modelLoadError = nil
        availableModels = []

        Task {
            do {
                let models: [String]
                let key = getAPIKey(for: aiProvider)
                guard !key.isEmpty else {
                    isLoadingModels = false
                    modelLoadError = "No API key set"
                    return
                }

                switch aiProvider {
                case .openai:
                    let client = OpenAIClient(apiKey: key)
                    let allModels = try await client.listModels()
                    models = allModels.map(\.id).filter { id in
                        !id.contains("whisper") && !id.contains("tts") &&
                        !id.contains("dall-e") && !id.contains("embedding")
                    }

                case .gemini:
                    let client = GeminiClient(apiKey: key)
                    let allModels = try await client.listModels()
                    models = allModels
                        .filter(\.supportsGeneration)
                        .map(\.modelId)
                        .sorted()
                }

                availableModels = models
                isLoadingModels = false
            } catch {
                isLoadingModels = false
                modelLoadError = "Failed to load: \(error.localizedDescription)"
            }
        }
    }

    func refreshPermissionStates() {
        microphoneState = Permissions.microphoneState()
        accessibilityTrusted = AccessibilityPermissions.isTrusted()
        inputMonitoringAllowed = InputMonitoringPermissions.isAllowed()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    var appBundlePath: String {
        Bundle.main.bundleURL.path
    }

    var menuBarSymbolName: String {
        switch activity {
        case .loading:
            return pulseTick ? "arrow.down.circle.fill" : "arrow.down.circle"
        case .idle:
            return "waveform"
        case .recording:
            return pulseTick ? "mic.circle.fill" : "mic.fill"
        case .transcribing:
            return pulseTick ? "waveform.circle.fill" : "waveform"
        }
    }

    func requestMicrophoneAccess() {
        Task {
            _ = await Permissions.requestMicrophoneAccess()
            await MainActor.run {
                self.microphoneState = Permissions.microphoneState()
            }
        }
    }

    func requestAccessibilityPrompt() {
        AccessibilityPermissions.prompt()
        accessibilityTrusted = AccessibilityPermissions.isTrusted()
    }

    func requestInputMonitoringAccess() {
        _ = InputMonitoringPermissions.request()
        inputMonitoringAllowed = InputMonitoringPermissions.isAllowed()
    }


    func saveSettings(newAPIKeyIfProvided apiKey: String) {
        UserDefaults.standard.set(promptTemplate, forKey: Keys.promptTemplate)
        UserDefaults.standard.set(promptModelName, forKey: Keys.promptModel)
        UserDefaults.standard.set(preferredLanguage, forKey: Keys.preferredLanguage)
        UserDefaults.standard.set(translationLanguage, forKey: Keys.translationLanguage)
        UserDefaults.standard.set(useToggleMode, forKey: Keys.useToggleMode)
        UserDefaults.standard.set(aiProvider.rawValue, forKey: Keys.aiProvider)

        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            do {
                try keychain.setString(trimmed, account: aiProvider.keychainAccount)
                refreshKeychainState()
                showSettingsFeedback("Saved \(aiProvider.displayName) API key", isError: false)
            } catch {
                showSettingsFeedback("Failed to save key: \(error)", isError: true)
            }
        } else {
            refreshKeychainState()
            showSettingsFeedback("Saved", isError: false)
        }
    }

    func clearAPIKey() {
        do {
            try keychain.delete(account: aiProvider.keychainAccount)
            if aiProvider == .openai {
                try? legacyKeychain.delete(account: aiProvider.keychainAccount)
            }
            refreshKeychainState()
            showSettingsFeedback("Cleared \(aiProvider.displayName) API key", isError: false)
        } catch {
            showSettingsFeedback("Failed to clear key: \(error)", isError: true)
        }
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func clearHistory() {
        transcriptHistory = []
        saveHistory()
        showSettingsFeedback("Cleared history", isError: false)
    }

    func toggleListening() {
        Task { await toggleListeningAsync() }
    }

    private func autoRestartListeningIfNeeded() {
        guard didFinishInit else { return }
        // Persist immediately so changes survive restarts
        UserDefaults.standard.set(preferredLanguage, forKey: Keys.preferredLanguage)
        UserDefaults.standard.set(translationLanguage, forKey: Keys.translationLanguage)
        UserDefaults.standard.set(useToggleMode, forKey: Keys.useToggleMode)

        guard isListeningEnabled else { return }
        Task {
            await toggleListeningAsync() // disable
            await toggleListeningAsync() // re-enable with new settings
        }
    }

    private func toggleListeningAsync() async {
        if isListeningEnabled {
            monitorRaw?.stop()
            monitorPrompt?.stop()
            monitorRaw = nil
            monitorPrompt = nil
            controller = nil
            stopPulsing()
            activity = .idle
            isListeningEnabled = false
            hotkeyRegistered = false
            hotkeyLastError = nil
            statusLine = "Idle"
            return
        }

        guard modelState == .ready else {
            statusLine = "Model not ready yet"
            showToast("WhisperKit model is still loading. Please wait.", variant: .warning)
            return
        }

        if Permissions.microphoneState() == .notDetermined {
            _ = await Permissions.requestMicrophoneAccess()
        }
        refreshPermissionStates()
        guard microphoneState == .authorized else {
            statusLine = "Microphone permission required"
            showSettingsWindow()
            return
        }

        if !accessibilityTrusted {
            statusLine = "Grant Accessibility permission (for paste)"
            AccessibilityPermissions.prompt()
            refreshPermissionStates()
        }

        do {
            // Prompt service is optional — only available when API key is set
            let promptSvc: (any PromptService)?
            let translationSvc: (any PromptService)?

            let key = getAPIKey(for: aiProvider)
            if !key.isEmpty {
                switch aiProvider {
                case .openai:
                    let client = OpenAIClient(apiKey: key)
                    promptSvc = OpenAIPromptService(client: client, model: promptModelName)
                    translationSvc = OpenAIPromptService(client: client, model: "gpt-4.1-mini")
                case .gemini:
                    let client = GeminiClient(apiKey: key)
                    promptSvc = GeminiPromptService(client: client, model: promptModelName)
                    translationSvc = GeminiPromptService(client: client, model: "gemini-2.0-flash")
                }
            } else {
                promptSvc = nil
                translationSvc = nil
            }

            let controller = HoldToTranscribeController(
                transcriber: whisperTranscriber,
                promptService: promptSvc,
                translationService: translationSvc,
                config: .init(language: preferredLanguage, translationLanguage: translationLanguage, promptTemplate: promptTemplate)
            )
            controller.setStateHandler { [weak self] state in
                Task { @MainActor in
                    guard let self else { return }
                    switch state {
                    case .idle:
                        self.statusLine = "Idle (Ctrl+Opt+Space; Ctrl+Opt+Cmd+Space = prompt)"
                    default:
                        self.statusLine = Self.stateLine(state)
                    }
                    self.updateActivity(from: state)

                    if case .failed(let message) = state {
                        self.showToast(message, variant: .error)
                    }
                }
            }
            controller.setResultHandler { [weak self] result in
                Task { @MainActor in
                    self?.recordResult(result)
                }
            }
            controller.setAmplitudeHandler { [weak self] level in
                Task { @MainActor in
                    guard let self else { return }
                    self.amplitudes.removeFirst()
                    self.amplitudes.append(CGFloat(level))
                }
            }

            let toggle = self.useToggleMode
            let rawMonitor = PressAndHoldHotkeyMonitor(
                hotkey: hotkeyConfig.transcriptHotkey(),
                carbonHotKeyID: 1,
                toggleMode: toggle,
                onPressed: { [weak self] in
                    controller.handleHotkeyPressed(behavior: .pasteTranscript)
                    Task { @MainActor in self?.lastHotkeyEventAt = Date() }
                },
                onReleased: { [weak self] in
                    controller.handleHotkeyReleased()
                    Task { @MainActor in self?.lastHotkeyEventAt = Date() }
                }
            )
            let promptMonitor = PressAndHoldHotkeyMonitor(
                hotkey: hotkeyConfig.promptedHotkey(),
                carbonHotKeyID: 2,
                toggleMode: toggle,
                onPressed: { [weak self] in
                    controller.handleHotkeyPressed(behavior: .pastePrompted)
                    Task { @MainActor in self?.lastHotkeyEventAt = Date() }
                },
                onReleased: { [weak self] in
                    controller.handleHotkeyReleased()
                    Task { @MainActor in self?.lastHotkeyEventAt = Date() }
                }
            )
            try rawMonitor.start()
            try promptMonitor.start()

            self.controller = controller
            self.monitorRaw = rawMonitor
            self.monitorPrompt = promptMonitor
            self.isListeningEnabled = true
            self.hotkeyRegistered = true
            self.hotkeyLastError = nil
            self.statusLine = "Idle (Ctrl+Opt+Space; Ctrl+Opt+Cmd+Space = prompt)"
            self.activity = .idle
        } catch PressAndHoldHotkeyMonitor.MonitorError.tapCreationFailed {
            statusLine = "Grant Input Monitoring permission (hotkey)"
            showSettingsWindow()
        } catch PressAndHoldHotkeyMonitor.MonitorError.hotKeyRegistrationFailed(let status) {
            hotkeyRegistered = false
            hotkeyLastError = "Hotkey registration failed (OSStatus \(status)). Try another hotkey."
            statusLine = "Hotkey registration failed"
            showSettingsWindow()
        } catch {
            hotkeyRegistered = false
            hotkeyLastError = "Enable failed: \(error)"
            statusLine = "Enable hotkey failed: \(error)"
        }
    }

    private func updateActivity(from state: HoldToTranscribeController.State) {
        switch state {
        case .idle:
            activity = .idle
            isRecording = false
            amplitudes = Array(repeating: 0, count: Self.amplitudeBarCount)
            stopPulsing()
        case .recording:
            activity = .recording
            isRecording = true
            startPulsingIfNeeded()
        case .transcribing:
            activity = .transcribing
            isRecording = false
            startPulsingIfNeeded()
        case .failed:
            activity = .idle
            isRecording = false
            amplitudes = Array(repeating: 0, count: Self.amplitudeBarCount)
            stopPulsing()
        }
    }

    private func startPulsingIfNeeded() {
        guard pulseTimer == nil else { return }
        pulseTick = false
        pulseTimer = Timer.scheduledTimer(withTimeInterval: Self.pulseInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.pulseTick.toggle()
            }
        }
        RunLoop.main.add(pulseTimer!, forMode: .common)
    }

    private func stopPulsing() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        pulseTick = false
    }

    private func showSettingsFeedback(_ message: String, isError: Bool) {
        settingsFeedback = message
        settingsFeedbackIsError = isError
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.feedbackDismissDelay) { [weak self] in
            guard let self else { return }
            self.settingsFeedback = nil
        }
    }

    private func showToast(_ message: String, variant: HSToastVariant = .info) {
        if toast == nil { toast = ToastWindowController() }
        toast?.show(message: message, variant: variant)
    }

    private func recordResult(_ result: HoldToTranscribeController.Result) {
        let mode: TranscriptHistoryItem.Mode
        switch result.behavior {
        case .pasteTranscript: mode = .transcript
        case .pastePrompted: mode = .prompted
        }

        let item = TranscriptHistoryItem(
            id: UUID().uuidString,
            date: Date(),
            mode: mode,
            transcript: result.transcript,
            finalText: result.finalText,
            didPaste: result.didPaste,
            didCopyToClipboard: result.didCopyToClipboard,
            errorMessage: result.errorMessage
        )

        transcriptHistory.insert(item, at: 0)
        if transcriptHistory.count > Self.maxHistoryCount {
            transcriptHistory = Array(transcriptHistory.prefix(Self.maxHistoryCount))
        }
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Keys.history) else { return }
        do {
            transcriptHistory = try JSONDecoder().decode([TranscriptHistoryItem].self, from: data)
        } catch {
            logger.error("Failed to decode history: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(transcriptHistory)
            UserDefaults.standard.set(data, forKey: Keys.history)
        } catch {
            logger.error("Failed to encode history: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func stateLine(_ state: HoldToTranscribeController.State) -> String {
        switch state {
        case .idle:
            return "Idle"
        case .recording:
            return "Listening… (release to transcribe)"
        case .transcribing:
            return "Transcribing…"
        case .failed(let message):
            return message
        }
    }
}

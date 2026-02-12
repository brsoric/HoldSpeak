import SwiftUI
import TranscribeHoldPasteKit

struct HotkeysTab: View {
    @ObservedObject var appModel: AppModel
    @State private var transcriptRecorderState: HSRecorderState = .idle
    @State private var promptedRecorderState: HSRecorderState = .idle
    @State private var localMonitor: Any?
    @State private var globalMonitor: Any?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HSLayout.gapSection) {
                ShortcutRecorder(
                    title: "Transcript Shortcut",
                    currentModifiers: appModel.hotkeyConfig.transcriptModifierLabels,
                    currentKey: appModel.hotkeyConfig.transcriptKeyLabel,
                    recorderState: $transcriptRecorderState,
                    onRecord: { startListening(for: .transcript) },
                    onReset: {
                        appModel.hotkeyConfig.transcriptKeyCode = HotkeyConfig.default.transcriptKeyCode
                        appModel.hotkeyConfig.transcriptModifiers = HotkeyConfig.default.transcriptModifiers
                        appModel.hotkeyConfig.save()
                        transcriptRecorderState = .idle
                    }
                )

                ShortcutRecorder(
                    title: "Prompted (AI Rewrite) Shortcut",
                    currentModifiers: appModel.hotkeyConfig.promptedModifierLabels,
                    currentKey: appModel.hotkeyConfig.promptedKeyLabel,
                    recorderState: $promptedRecorderState,
                    onRecord: { startListening(for: .prompted) },
                    onReset: {
                        appModel.hotkeyConfig.promptedKeyCode = HotkeyConfig.default.promptedKeyCode
                        appModel.hotkeyConfig.promptedModifiers = HotkeyConfig.default.promptedModifiers
                        appModel.hotkeyConfig.save()
                        promptedRecorderState = .idle
                    }
                )

                Divider()

                VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
                    HStack(spacing: HSLayout.gapMedium) {
                        HSButton(
                            label: appModel.isListeningEnabled ? "Disable Hotkey" : "Enable Hotkey",
                            icon: appModel.isListeningEnabled ? "stop.circle" : "play.circle",
                            variant: appModel.isListeningEnabled ? .destructive : .success,
                            action: { appModel.toggleListening() }
                        )

                        if appModel.hotkeyRegistered {
                            StatusDot(state: .ready)
                            Text("Registered")
                                .font(.hs_caption)
                                .foregroundStyle(Color.hs_text_secondary)
                        }
                    }

                    if let err = appModel.hotkeyLastError {
                        Text(err)
                            .font(.hs_caption)
                            .foregroundStyle(Color.hs_error)
                    }

                    if let date = appModel.lastHotkeyEventAt {
                        Text("Last event: \(date.formatted(date: .abbreviated, time: .standard))")
                            .font(.hs_caption)
                            .foregroundStyle(Color.hs_text_tertiary)
                    }
                }
            }
            .padding(HSLayout.paddingCard)
        }
        .onDisappear { stopKeyMonitors() }
    }

    // MARK: - Key Capture

    private enum Target { case transcript, prompted }

    private func startListening(for target: Target) {
        stopKeyMonitors()

        switch target {
        case .transcript:
            transcriptRecorderState = .listening
            promptedRecorderState = .idle
        case .prompted:
            promptedRecorderState = .listening
            transcriptRecorderState = .idle
        }

        // Ensure app is active so it can receive key events
        NSApp.activate(ignoringOtherApps: true)

        // Use both local and global monitors for maximum compatibility
        // Local monitor: captures events when app window is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .keyDown {
                handleKeyDown(event: event, target: target)
            }
            return event
        }

        // Global monitor: captures events even when another app has focus
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            handleKeyDown(event: event, target: target)
        }
    }

    private func handleKeyDown(event: NSEvent, target: Target) {
        // Escape cancels recording
        if event.keyCode == 53 {
            cancelListening()
            return
        }

        let keyCode = event.keyCode
        let carbonMods = carbonModifiers(from: event.modifierFlags)

        // Require at least one modifier for a hotkey
        guard carbonMods != 0 else { return }

        switch target {
        case .transcript:
            if keyCode == appModel.hotkeyConfig.promptedKeyCode &&
                carbonMods == appModel.hotkeyConfig.promptedModifiers {
                transcriptRecorderState = .conflict(message: "Same as Prompted shortcut")
                return
            }
            appModel.hotkeyConfig.transcriptKeyCode = keyCode
            appModel.hotkeyConfig.transcriptModifiers = carbonMods
            appModel.hotkeyConfig.save()
            transcriptRecorderState = .captured(
                modifiers: appModel.hotkeyConfig.transcriptModifierLabels,
                key: appModel.hotkeyConfig.transcriptKeyLabel
            )
        case .prompted:
            if keyCode == appModel.hotkeyConfig.transcriptKeyCode &&
                carbonMods == appModel.hotkeyConfig.transcriptModifiers {
                promptedRecorderState = .conflict(message: "Same as Transcript shortcut")
                return
            }
            appModel.hotkeyConfig.promptedKeyCode = keyCode
            appModel.hotkeyConfig.promptedModifiers = carbonMods
            appModel.hotkeyConfig.save()
            promptedRecorderState = .captured(
                modifiers: appModel.hotkeyConfig.promptedModifierLabels,
                key: appModel.hotkeyConfig.promptedKeyLabel
            )
        }

        stopKeyMonitors()
    }

    private func cancelListening() {
        transcriptRecorderState = .idle
        promptedRecorderState = .idle
        stopKeyMonitors()
    }

    private func stopKeyMonitors() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        localMonitor = nil
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        globalMonitor = nil
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.control) { mods |= 0x0100 }
        if flags.contains(.shift)   { mods |= 0x0200 }
        if flags.contains(.command) { mods |= 0x0400 }
        if flags.contains(.option)  { mods |= 0x0800 }
        return mods
    }
}

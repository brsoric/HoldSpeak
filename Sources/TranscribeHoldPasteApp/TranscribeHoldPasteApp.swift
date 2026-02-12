import SwiftUI
import TranscribeHoldPasteKit

@main
struct TranscribeHoldPasteApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: HSLayout.gapMedium) {
                ModelStatusCard(
                    modelName: "WhisperKit Small",
                    state: appModel.dsModelState
                )

                if !appModel.isListeningEnabled {
                    Text(appModel.statusLine)
                        .font(.hs_body)
                        .foregroundStyle(Color.hs_text_secondary)
                        .lineLimit(2)
                }

                if appModel.isRecording {
                    LiveWaveform(isActive: true, amplitudes: $appModel.amplitudes)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                if appModel.isListeningEnabled {
                    shortcutLine(
                        label: "Transcript:",
                        modifiers: appModel.hotkeyConfig.transcriptModifierLabels,
                        key: appModel.hotkeyConfig.transcriptKeyLabel
                    )
                    shortcutLine(
                        label: "Prompted:",
                        modifiers: appModel.hotkeyConfig.promptedModifierLabels,
                        key: appModel.hotkeyConfig.promptedKeyLabel
                    )
                }

                Divider()

                HStack(spacing: HSLayout.gapSmall) {
                    HSButton(
                        label: appModel.isListeningEnabled ? "Disable" : "Enable",
                        icon: appModel.isListeningEnabled ? "stop.circle" : "play.circle",
                        variant: appModel.isListeningEnabled ? .destructive : .success,
                        action: { appModel.toggleListening() }
                    )
                    HSButton(label: "Settings", icon: "gear", variant: .secondary) {
                        appModel.showSettingsWindow()
                    }
                }

                HSButton(label: "Quit", icon: "xmark.circle", variant: .ghost) {
                    appModel.quit()
                }
            }
            .padding(HSLayout.paddingCard)
            .frame(width: HSLayout.menuBarDropdownW)
            .animation(HSMotion.adaptiveSpringSmooth, value: appModel.isRecording)
        } label: {
            Image(systemName: appModel.menuBarSymbolName)
                .accessibilityLabel(Text("HoldSpeak"))
        }
    }

    private func shortcutLine(label: String, modifiers: [String], key: String) -> some View {
        let combo = (modifiers + [key]).joined(separator: " + ")
        return (
            Text(label + " ")
                .font(.hs_caption)
                .foregroundColor(Color.hs_text_tertiary)
            + Text(combo)
                .font(.hs_caption.bold())
                .foregroundColor(Color.hs_text_secondary)
        )
    }
}

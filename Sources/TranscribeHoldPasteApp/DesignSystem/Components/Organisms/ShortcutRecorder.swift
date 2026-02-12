import SwiftUI

enum HSRecorderState: Equatable {
    case idle
    case listening
    case captured(modifiers: [String], key: String)
    case conflict(message: String)
}

struct ShortcutRecorder: View {
    let title: String
    let currentModifiers: [String]
    let currentKey: String
    @Binding var recorderState: HSRecorderState
    let onRecord: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapMedium) {
            Text(title)
                .font(.hs_heading_sm)
                .foregroundStyle(Color.hs_text_primary)

            HStack(spacing: HSLayout.gapSmall) {
                ShortcutDisplay(modifiers: displayModifiers, key: displayKey)

                Spacer()

                if case .listening = recorderState {
                    Text("Press shortcut...")
                        .font(.hs_caption)
                        .foregroundStyle(Color.hs_interactive)

                    HSButton(label: "Cancel", variant: .ghost, size: .sm) {
                        recorderState = .idle
                    }
                } else {
                    HSButton(label: "Record", icon: "record.circle", variant: .secondary, size: .sm, action: onRecord)
                    HSButton(label: "Reset", variant: .ghost, size: .sm, action: onReset)
                }
            }
            .padding(HSCardToken.padding)
            .background(
                RoundedRectangle(cornerRadius: HSShortcutToken.radius, style: .continuous)
                    .fill(Color.hs_surface_secondary.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: HSShortcutToken.radius, style: .continuous)
                            .stroke(isListening ? Color.hs_interactive : Color.hs_border_subtle, lineWidth: isListening ? 1.5 : 0.5)
                    )
            )
            .animation(HSMotion.adaptiveSpringSmooth, value: recorderState)

            if case .conflict(let msg) = recorderState {
                HStack(spacing: HSSpace.xxs.rawValue) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.hs_caption)
                    Text(msg)
                        .font(.hs_caption)
                }
                .foregroundStyle(Color.hs_error)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) shortcut: \(displayModifiers.joined(separator: " ")) \(displayKey)")
    }

    private var isListening: Bool {
        if case .listening = recorderState { return true }
        return false
    }

    private var displayModifiers: [String] {
        if case .captured(let mods, _) = recorderState { return mods }
        return currentModifiers
    }

    private var displayKey: String {
        if case .captured(_, let key) = recorderState { return key }
        return currentKey
    }
}

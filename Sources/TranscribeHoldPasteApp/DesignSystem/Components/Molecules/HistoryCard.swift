import SwiftUI

struct HistoryCard: View {
    let mode: AppModel.TranscriptHistoryItem.Mode
    let date: Date
    let transcript: String?
    let finalText: String?
    let errorMessage: String?
    let onCopy: (String) -> Void
    @State private var isHovered = false
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: HSCardToken.gap) {
            HStack(spacing: HSLayout.gapSmall) {
                // Mode badge
                HStack(spacing: HSSpace.xxxs.rawValue) {
                    Image(systemName: mode == .prompted ? "sparkles" : "waveform")
                        .font(.hs_tiny)
                    Text(mode == .prompted ? "AI" : "Raw")
                        .font(.hs_tiny)
                }
                .foregroundStyle(mode == .prompted ? Color.hs_ai_accent : Color.hs_text_tertiary)
                .padding(.horizontal, HSSpace.xs.rawValue)
                .padding(.vertical, HSSpace.xxxs.rawValue)
                .background(
                    Capsule()
                        .fill(mode == .prompted ? Color.hs_fill_ai_bg : Color.hs_surface_secondary)
                )

                Text(date.formatted(.dateTime.hour().minute()))
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_text_tertiary)

                Spacer()

                if let text = finalText, !text.isEmpty {
                    Button {
                        onCopy(text)
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCopied = false }
                    } label: {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.hs_caption)
                            .foregroundStyle(showCopied ? Color.hs_success : Color.hs_text_secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered || showCopied ? 1.0 : 0.0)
                    .animation(.easeOut(duration: HSMotion.fast), value: isHovered)
                    .accessibilityLabel(showCopied ? "Copied" : "Copy text")
                }
            }

            if let err = errorMessage, !err.isEmpty {
                Text(err)
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_error)
            }

            if let preview = (finalText ?? transcript)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !preview.isEmpty {
                Text(preview)
                    .font(.hs_body)
                    .foregroundStyle(Color.hs_text_primary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
        }
        .padding(HSCardToken.padding)
        .background(
            RoundedRectangle(cornerRadius: HSCardToken.radius, style: .continuous)
                .fill(Color.hs_surface_secondary.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: HSCardToken.radius, style: .continuous)
                        .stroke(Color.hs_border_subtle)
                )
        )
        .scaleEffect(isHovered ? HSCardToken.hoverScale : 1.0)
        .shadow(
            color: isHovered ? HSShadow.sm.color : .clear,
            radius: isHovered ? HSShadow.sm.radius : 0
        )
        .animation(HSMotion.adaptiveSpringSnap, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

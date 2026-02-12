import SwiftUI

struct ModelStatusCard: View {
    let modelName: String
    let state: HSModelState
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: HSCardToken.gap) {
            HStack(spacing: HSLayout.gapSmall) {
                Image(systemName: "cpu")
                    .font(.system(size: HSLayout.iconMd))
                    .foregroundStyle(Color.hs_text_secondary)

                Text("WhisperKit Model")
                    .font(.hs_heading_sm)
                    .foregroundStyle(Color.hs_text_primary)

                Spacer()

                statusBadge
            }

            Text(modelName)
                .font(.hs_mono_sm)
                .foregroundStyle(Color.hs_text_tertiary)
        }
        .padding(HSCardToken.padding)
        .background(
            RoundedRectangle(cornerRadius: HSCardToken.radius, style: .continuous)
                .fill(Color.hs_surface_secondary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: HSCardToken.radius, style: .continuous)
                        .stroke(Color.hs_border_subtle)
                )
        )
        .scaleEffect(isHovered ? HSCardToken.hoverScale : 1.0)
        .animation(HSMotion.adaptiveSpringSnap, value: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("WhisperKit Model \(modelName), \(stateLabel)")
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch state {
        case .loading:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading")
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_processing)
            }
        case .ready:
            HStack(spacing: 4) {
                StatusDot(state: .ready)
                Text("Ready")
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_success)
            }
        case .error:
            HStack(spacing: 4) {
                StatusDot(state: .error)
                Text("Error")
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_error)
            }
        }
    }

    private var stateLabel: String {
        switch state {
        case .loading: return "Loading"
        case .ready: return "Ready"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

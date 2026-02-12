import SwiftUI

struct PermissionPanel: View {
    let microphoneGranted: Bool
    let accessibilityTrusted: Bool
    let inputMonitoringAllowed: Bool
    let appBundlePath: String
    let onRequestMic: () -> Void
    let onRequestAccessibility: () -> Void
    let onRequestInputMonitoring: () -> Void
    let onRefresh: () -> Void
    let onCopyPath: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapSection) {
            VStack(spacing: HSLayout.gapMedium) {
                permissionRow(
                    icon: "mic.fill",
                    label: "Microphone",
                    description: "Record audio for transcription",
                    granted: microphoneGranted,
                    action: onRequestMic
                )
                permissionRow(
                    icon: "hand.raised.fill",
                    label: "Accessibility",
                    description: "Simulate Cmd+V to paste text",
                    granted: accessibilityTrusted,
                    action: onRequestAccessibility
                )
                permissionRow(
                    icon: "keyboard",
                    label: "Input Monitoring",
                    description: "Capture global keyboard shortcuts",
                    granted: inputMonitoringAllowed,
                    action: onRequestInputMonitoring
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
                Text("App location (for manual permission grant)")
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_text_tertiary)

                HStack(spacing: HSLayout.gapSmall) {
                    Text(appBundlePath)
                        .font(.hs_mono_sm)
                        .foregroundStyle(Color.hs_text_secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)

                    HSButton(label: "Copy", icon: "doc.on.doc", variant: .ghost, size: .sm, action: onCopyPath)
                }
            }

            HStack {
                Spacer()
                HSButton(label: "Refresh", icon: "arrow.clockwise", variant: .secondary, size: .sm, action: onRefresh)
            }
        }
    }

    @ViewBuilder
    private func permissionRow(icon: String, label: String, description: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: HSLayout.gapSmall) {
            Image(systemName: icon)
                .font(.system(size: HSLayout.iconMd))
                .foregroundStyle(granted ? Color.hs_success : Color.hs_warning)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.hs_label)
                    .foregroundStyle(Color.hs_text_primary)
                Text(description)
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_text_tertiary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.hs_success)
            } else {
                HSButton(label: "Grant", variant: .primary, size: .sm, action: action)
            }
        }
        .padding(HSCardToken.padding)
        .background(
            RoundedRectangle(cornerRadius: HSCardToken.radius, style: .continuous)
                .fill(granted ? Color.hs_fill_success_bg.opacity(0.3) : Color.hs_fill_warning_bg.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: HSCardToken.radius, style: .continuous)
                        .stroke(granted ? Color.hs_success.opacity(0.15) : Color.hs_warning.opacity(0.15))
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(granted ? "Granted" : "Not granted")")
    }
}

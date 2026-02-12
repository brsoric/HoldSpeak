import AppKit
import SwiftUI

struct PermissionsTab: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HSLayout.gapSection) {
                VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
                    Text("App Permissions")
                        .font(.hs_heading_sm)
                        .foregroundStyle(Color.hs_text_primary)

                    Text("HoldSpeak needs these permissions to record audio, detect hotkeys, and paste text.")
                        .font(.hs_body)
                        .foregroundStyle(Color.hs_text_secondary)
                }

                PermissionPanel(
                    microphoneGranted: appModel.microphoneState == .authorized,
                    accessibilityTrusted: appModel.accessibilityTrusted,
                    inputMonitoringAllowed: appModel.inputMonitoringAllowed,
                    appBundlePath: appModel.appBundlePath,
                    onRequestMic: {
                        appModel.requestMicrophoneAccess()
                        SystemSettingsLinks.openPrivacyMicrophone()
                    },
                    onRequestAccessibility: {
                        appModel.requestAccessibilityPrompt()
                        SystemSettingsLinks.openPrivacyAccessibility()
                    },
                    onRequestInputMonitoring: {
                        appModel.requestInputMonitoringAccess()
                        SystemSettingsLinks.openPrivacyInputMonitoring()
                    },
                    onRefresh: {
                        appModel.refreshPermissionStates()
                    },
                    onCopyPath: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(appModel.appBundlePath, forType: .string)
                    }
                )
            }
            .padding(HSLayout.paddingCard)
        }
    }
}

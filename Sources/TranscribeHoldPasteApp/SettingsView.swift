import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        TabView {
            GeneralTab(appModel: appModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            HotkeysTab(appModel: appModel)
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }

            AIRewritingTab(appModel: appModel)
                .tabItem {
                    Label("AI Rewriting", systemImage: "sparkles")
                }

            HistoryTab(appModel: appModel)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            PermissionsTab(appModel: appModel)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(minWidth: 560, minHeight: 480)
        .onAppear {
            appModel.refreshPermissionStates()
        }
    }
}

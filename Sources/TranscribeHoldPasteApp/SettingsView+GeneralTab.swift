import SwiftUI

struct GeneralTab: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HSLayout.gapSection) {
                modelSection
                languageSection
                translationSection
                recordingModeSection
                Divider()
                footerSection
            }
            .padding(HSLayout.paddingCard)
        }
    }

    @ViewBuilder
    private var modelSection: some View {
        ModelStatusCard(
            modelName: "WhisperKit Small",
            state: appModel.dsModelState
        )
    }

    @ViewBuilder
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
            Text("Transcription Language")
                .font(.hs_heading_sm)
                .foregroundStyle(Color.hs_text_primary)

            Picker("Language", selection: Binding(
                get: { appModel.preferredLanguage ?? "__auto__" },
                set: { appModel.preferredLanguage = $0 == "__auto__" ? nil : $0 }
            )) {
                Text("Auto-detect").tag("__auto__")
                Text("English").tag("en")
                Text("Português").tag("pt")
                Text("Deutsch").tag("de")
                Text("Lëtzebuergesch").tag("lb")
                Text("Русский").tag("ru")
                Text("Українська").tag("uk")
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 200)
        }
    }

    @ViewBuilder
    private var translationSection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
            Text("Translate To")
                .font(.hs_heading_sm)
                .foregroundStyle(Color.hs_text_primary)

            Picker("Translation", selection: Binding(
                get: { appModel.translationLanguage ?? "__none__" },
                set: { appModel.translationLanguage = $0 == "__none__" ? nil : $0 }
            )) {
                Text("None (no translation)").tag("__none__")
                Text("English").tag("en")
                Text("Português").tag("pt")
                Text("Deutsch").tag("de")
                Text("Lëtzebuergesch").tag("lb")
                Text("Русский").tag("ru")
                Text("Українська").tag("uk")
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 200)

            Text("English: local translation (no API needed). Other languages: requires API key.")
                .font(.hs_caption)
                .foregroundStyle(Color.hs_text_tertiary)
        }
    }

    @ViewBuilder
    private var recordingModeSection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
            Toggle(isOn: $appModel.useToggleMode) {
                Text("Toggle mode")
                    .font(.hs_heading_sm)
                    .foregroundStyle(Color.hs_text_primary)
            }
            .toggleStyle(.switch)

            Text(appModel.useToggleMode
                ? "Press hotkey to start, press Esc or same hotkey to stop."
                : "Hold hotkey to record, release to transcribe.")
                .font(.hs_caption)
                .foregroundStyle(Color.hs_text_tertiary)
        }
    }

    @ViewBuilder
    private var footerSection: some View {
        HStack {
            Spacer()
            Text("Max recording: 10 min")
                .font(.hs_caption)
                .foregroundStyle(Color.hs_text_tertiary)
        }
    }
}

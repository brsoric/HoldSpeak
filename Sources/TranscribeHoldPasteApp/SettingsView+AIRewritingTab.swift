import SwiftUI
import TranscribeHoldPasteKit

struct AIRewritingTab: View {
    @ObservedObject var appModel: AppModel
    @State private var apiKeyInput: String = ""
    @State private var showAPIKey: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HSLayout.gapSection) {
                headerSection
                providerSection
                apiKeySection
                Divider()
                modelSection
                promptTemplateSection
                saveSection
            }
            .padding(HSLayout.paddingCard)
        }
        .onAppear {
            appModel.refreshKeychainState()
        }
        .onChange(of: appModel.aiProvider) { _ in
            apiKeyInput = ""
            appModel.refreshKeychainState()
            appModel.availableModels = []
            appModel.modelLoadError = nil
            // Set default model for the new provider
            if appModel.aiProvider == .gemini {
                appModel.promptModelName = "gemini-2.0-flash"
            } else {
                appModel.promptModelName = "gpt-4o-mini"
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapMedium) {
            VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
                Text("Optional — AI Rewriting")
                    .font(.hs_heading_sm)
                    .foregroundStyle(Color.hs_text_primary)

                Text("Transcription works fully offline. An API key enables the prompted mode which rewrites your speech using AI.")
                    .font(.hs_body)
                    .foregroundStyle(Color.hs_text_secondary)
            }

            // How it works
            VStack(alignment: .leading, spacing: HSSpace.sm.rawValue) {
                Text("How it works")
                    .font(.hs_label)
                    .foregroundStyle(Color.hs_text_primary)

                modeRow(
                    icon: "waveform",
                    title: "Rewrite mode",
                    hotkey: appModel.hotkeyConfig.promptedDescription,
                    description: "Speak freely — AI polishes your text before pasting"
                )

                modeRow(
                    icon: "text.cursor",
                    title: "Context mode",
                    hotkey: "Select text + " + appModel.hotkeyConfig.promptedDescription,
                    description: "Select text first, then speak an instruction (e.g. \"translate to English\", \"summarize\"). Result is copied to clipboard."
                )
            }
            .padding(HSSpace.sm.rawValue)
            .background(
                RoundedRectangle(cornerRadius: HSRadius.md.rawValue)
                    .fill(Color.hs_text_tertiary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: HSRadius.md.rawValue)
                    .stroke(Color.hs_border_subtle, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func modeRow(icon: String, title: String, hotkey: String, description: String) -> some View {
        HStack(alignment: .top, spacing: HSSpace.sm.rawValue) {
            Image(systemName: icon)
                .foregroundStyle(Color.hs_success)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: HSSpace.xs.rawValue) {
                    Text(title)
                        .font(.hs_caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.hs_text_primary)

                    Text(hotkey)
                        .font(.hs_mono_sm)
                        .foregroundStyle(Color.hs_text_tertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.hs_text_tertiary.opacity(0.1))
                        )
                }

                Text(description)
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_text_secondary)
            }
        }
    }

    // MARK: - Provider Picker

    @ViewBuilder
    private var providerSection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
            Text("AI Provider")
                .font(.hs_label)
                .foregroundStyle(Color.hs_text_primary)

            Picker("Provider", selection: $appModel.aiProvider) {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: 250)
        }
    }

    // MARK: - API Key

    @ViewBuilder
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapMedium) {
            Text("\(appModel.aiProvider.displayName) API Key")
                .font(.hs_label)
                .foregroundStyle(Color.hs_text_primary)

            // Connection status banner
            HStack(spacing: HSSpace.sm.rawValue) {
                Image(systemName: appModel.currentProviderKeyIsSet ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(appModel.currentProviderKeyIsSet ? Color.hs_success : Color.hs_text_tertiary)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 2) {
                    Text(appModel.currentProviderKeyIsSet
                        ? "\(appModel.aiProvider.displayName) connected"
                        : "\(appModel.aiProvider.displayName) not connected")
                        .font(.hs_label)
                        .foregroundStyle(appModel.currentProviderKeyIsSet ? Color.hs_success : Color.hs_text_secondary)

                    Text(appModel.currentProviderKeyIsSet
                        ? "API key saved in Keychain — AI rewriting enabled"
                        : "Add an API key to enable AI rewriting")
                        .font(.hs_caption)
                        .foregroundStyle(Color.hs_text_tertiary)
                }

                Spacer()

                if appModel.currentProviderKeyIsSet {
                    HSButton(label: "Clear", variant: .ghost, size: .sm) {
                        apiKeyInput = ""
                        appModel.clearAPIKey()
                    }
                }
            }
            .padding(HSSpace.sm.rawValue)
            .background(
                RoundedRectangle(cornerRadius: HSRadius.md.rawValue)
                    .fill(appModel.currentProviderKeyIsSet
                        ? Color.hs_success.opacity(0.08)
                        : Color.hs_text_tertiary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: HSRadius.md.rawValue)
                    .stroke(appModel.currentProviderKeyIsSet
                        ? Color.hs_success.opacity(0.3)
                        : Color.hs_border_subtle, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: HSSpace.xxs.rawValue) {
                Text("New API key (leave blank to keep existing)")
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_text_tertiary)

                HStack(spacing: HSLayout.gapSmall) {
                    if showAPIKey {
                        TextField(apiKeyPlaceholder, text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.hs_mono_sm)
                    } else {
                        SecureField(apiKeyPlaceholder, text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.hs_mono_sm)
                    }
                    Toggle("Show", isOn: $showAPIKey)
                        .toggleStyle(.switch)
                        .fixedSize()
                }
            }
        }
    }

    private var apiKeyPlaceholder: String {
        switch appModel.aiProvider {
        case .openai: return "sk-..."
        case .gemini: return "AIza..."
        }
    }

    // MARK: - Model Selection

    @ViewBuilder
    private var modelSection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapMedium) {
            HStack {
                Text("Prompt Model")
                    .font(.hs_label)
                    .foregroundStyle(Color.hs_text_primary)
                Spacer()
                if appModel.currentProviderKeyIsSet {
                    HSButton(label: "Fetch Models", variant: .ghost, size: .sm) {
                        appModel.fetchAvailableModels()
                    }
                }
            }

            if appModel.isLoadingModels {
                ProgressView("Loading models...")
                    .font(.hs_caption)
            }

            if let error = appModel.modelLoadError {
                Text(error)
                    .font(.hs_caption)
                    .foregroundStyle(Color.hs_error)
            }

            if !appModel.availableModels.isEmpty {
                Picker("Model", selection: $appModel.promptModelName) {
                    ForEach(appModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 300)
            } else {
                Picker("Model", selection: $appModel.promptModelName) {
                    ForEach(defaultModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 300)
            }

            TextField("Custom model name", text: $appModel.promptModelName)
                .textFieldStyle(.roundedBorder)
                .font(.hs_mono_sm)
                .frame(maxWidth: 300)

            Text(recommendedNote)
                .font(.hs_caption)
                .foregroundStyle(Color.hs_text_tertiary)
        }
    }

    private var defaultModels: [String] {
        switch appModel.aiProvider {
        case .openai: return [
            "gpt-4o-mini",           // Fast, cheap, good quality
            "gpt-4o",                // GPT-4 Omni (multimodal, latest)
            "gpt-4-turbo",           // GPT-4 Turbo
            "gpt-4",                 // GPT-4
            "gpt-3.5-turbo",         // GPT-3.5 Turbo (fastest, cheapest)
            "o1-preview",            // O1 reasoning model (preview)
            "o1-mini",               // O1 mini reasoning model
            "gpt-4.1-nano",          // Custom/legacy
            "gpt-4.1-mini"           // Custom/legacy
        ]
        case .gemini: return ["gemini-2.0-flash", "gemini-2.0-flash-lite", "gemini-2.5-flash"]
        }
    }

    private var recommendedNote: String {
        switch appModel.aiProvider {
        case .openai:
            return "Recommended: gpt-4o-mini (fast & cheap), gpt-4o (best quality), gpt-3.5-turbo (cheapest)"
        case .gemini:
            return "Recommended: gemini-2.0-flash (fast, free tier available), gemini-2.0-flash-lite (fastest)"
        }
    }

    // MARK: - Prompt Template

    @ViewBuilder
    private var promptTemplateSection: some View {
        VStack(alignment: .leading, spacing: HSLayout.gapSmall) {
            Text("Prompt Template")
                .font(.hs_label)
                .foregroundStyle(Color.hs_text_primary)

            Text("System instruction sent with your transcript. Used only for Ctrl+Opt+Cmd+Space.")
                .font(.hs_caption)
                .foregroundStyle(Color.hs_text_tertiary)

            TextEditor(text: $appModel.promptTemplate)
                .font(.hs_mono)
                .frame(minHeight: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: HSRadius.md.rawValue)
                        .stroke(Color.hs_border_subtle)
                )
        }
    }

    // MARK: - Save

    @ViewBuilder
    private var saveSection: some View {
        HStack(spacing: HSLayout.gapSmall) {
            HSButton(label: "Save", icon: "checkmark", variant: .primary) {
                appModel.saveSettings(newAPIKeyIfProvided: apiKeyInput)
                apiKeyInput = ""
            }

            if let feedback = appModel.settingsFeedback {
                Text(feedback)
                    .font(.hs_caption)
                    .foregroundStyle(appModel.settingsFeedbackIsError ? Color.hs_error : Color.hs_success)
            }
        }
    }
}

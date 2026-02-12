import SwiftUI

struct HistoryTab: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HSLayout.gapSection) {
                historyHeader
                historyList
            }
            .padding(HSLayout.paddingCard)
        }
    }

    @ViewBuilder
    private var historyHeader: some View {
        HStack {
            Text("History")
                .font(.hs_heading_sm)
                .foregroundStyle(Color.hs_text_primary)
            Spacer()
            if !appModel.transcriptHistory.isEmpty {
                HSButton(label: "Clear", icon: "trash", variant: .ghost, size: .sm) {
                    appModel.clearHistory()
                }
            }
        }
    }

    @ViewBuilder
    private var historyList: some View {
        if appModel.transcriptHistory.isEmpty {
            Text("No transcripts yet. Use the hotkey to create your first one.")
                .font(.hs_body)
                .foregroundStyle(Color.hs_text_tertiary)
                .padding(.vertical, HSLayout.gapMedium)
        } else {
            ForEach(appModel.transcriptHistory) { item in
                historyCard(for: item)
            }
        }
    }

    @ViewBuilder
    private func historyCard(for item: AppModel.TranscriptHistoryItem) -> some View {
        HistoryCard(
            mode: item.mode,
            date: item.date,
            transcript: item.transcript,
            finalText: item.finalText,
            errorMessage: item.errorMessage,
            onCopy: { text in
                appModel.copyToClipboard(text)
            }
        )
    }
}

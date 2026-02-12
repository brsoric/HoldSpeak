import SwiftUI

struct StatusRow: View {
    let label: String
    let value: String
    let state: HSAppState

    var body: some View {
        HStack(spacing: HSLayout.gapSmall) {
            StatusDot(state: state)
            Text(label)
                .font(.hs_label)
                .foregroundStyle(Color.hs_text_primary)
            Spacer()
            Text(value)
                .font(.hs_caption)
                .foregroundStyle(Color.hs_text_secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

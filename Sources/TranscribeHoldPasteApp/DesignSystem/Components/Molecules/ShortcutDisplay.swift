import SwiftUI

struct ShortcutDisplay: View {
    let modifiers: [String]
    let key: String

    var body: some View {
        HStack(spacing: HSShortcutToken.keyCapGap) {
            ForEach(modifiers, id: \.self) { mod in
                KeyBadge(label: mod)
            }
            Image(systemName: "plus")
                .font(.hs_tiny.bold())
                .foregroundStyle(Color.hs_text_tertiary)
            KeyBadge(label: key)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(modifiers.joined(separator: " ")) \(key)")
    }
}

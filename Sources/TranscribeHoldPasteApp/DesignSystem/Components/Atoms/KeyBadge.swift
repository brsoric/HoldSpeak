import SwiftUI

struct KeyBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.hs_key_cap)
            .foregroundStyle(Color.hs_text_secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .frame(minWidth: HSShortcutToken.keyCapSize, minHeight: HSShortcutToken.keyCapSize)
            .background(
                RoundedRectangle(cornerRadius: HSShortcutToken.keyCapRadius, style: .continuous)
                    .fill(Color.hs_surface_secondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: HSShortcutToken.keyCapRadius, style: .continuous)
                            .stroke(Color.hs_border_default, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 0.5, y: 0.5)
            )
            .accessibilityLabel(label)
    }
}

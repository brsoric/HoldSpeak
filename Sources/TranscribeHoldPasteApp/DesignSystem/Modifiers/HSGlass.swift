import SwiftUI

struct HSGlassModifier: ViewModifier {
    var radius: CGFloat = HSRadius.xl.rawValue

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(.white.opacity(0.10))
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }
}

extension View {
    func hsGlass(radius: CGFloat = HSRadius.xl.rawValue) -> some View {
        modifier(HSGlassModifier(radius: radius))
    }
}

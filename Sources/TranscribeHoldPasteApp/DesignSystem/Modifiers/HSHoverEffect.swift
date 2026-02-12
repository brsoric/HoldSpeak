import SwiftUI

struct HSHoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .shadow(
                color: isHovered ? HSShadow.sm.color : .clear,
                radius: isHovered ? HSShadow.sm.radius : 0
            )
            .animation(HSMotion.adaptiveSpringSnap, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func hsHover(scale: CGFloat = 1.01) -> some View {
        modifier(HSHoverEffectModifier(scale: scale))
    }
}

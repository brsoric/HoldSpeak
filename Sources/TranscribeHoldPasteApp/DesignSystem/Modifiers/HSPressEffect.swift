import SwiftUI

struct HSPressEffectModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(HSMotion.adaptiveSpringSnap, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, pressing: { isPressed = $0 }, perform: {})
    }
}

extension View {
    func hsPress() -> some View {
        modifier(HSPressEffectModifier())
    }
}

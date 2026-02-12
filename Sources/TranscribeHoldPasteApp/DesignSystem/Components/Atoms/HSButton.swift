import SwiftUI

enum HSButtonVariant {
    case primary
    case secondary
    case ghost
    case destructive
    case success
    case ai
}

enum HSButtonSize { case sm, md, lg }

struct HSButton: View {
    let label: String
    var icon: String? = nil
    var variant: HSButtonVariant = .primary
    var size: HSButtonSize = .md
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HSButtonToken.iconGap) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize))
                }
                Text(label)
                    .font(HSButtonToken.font)
            }
            .padding(.horizontal, HSButtonToken.paddingH)
            .frame(height: buttonHeight)
            .foregroundStyle(foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: HSButtonToken.radius, style: .continuous)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: HSButtonToken.radius, style: .continuous)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: HSButtonToken.radius))
        }
        .buttonStyle(HSButtonPressStyle())
        .accessibilityLabel(label)
    }

    private var buttonHeight: CGFloat {
        switch size {
        case .sm: return HSButtonToken.heightSm
        case .md: return HSButtonToken.heightMd
        case .lg: return HSButtonToken.heightLg
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .sm: return HSLayout.iconSm
        case .md: return HSLayout.iconMd
        case .lg: return HSLayout.iconLg
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:     return .hs_interactive
        case .secondary:   return .clear
        case .ghost:       return .clear
        case .destructive: return .hs_error
        case .success:     return .hs_success
        case .ai:          return .hs_ai_accent
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive, .success, .ai: return .white
        case .secondary: return .hs_text_primary
        case .ghost:     return .hs_interactive
        }
    }

    private var borderColor: Color {
        variant == .secondary ? .hs_border_default : .clear
    }

    private var borderWidth: CGFloat {
        variant == .secondary ? 1.0 : 0
    }
}

private struct HSButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? HSButtonToken.scalePressed : 1.0)
            .opacity(configuration.isPressed ? 0.90 : 1.0)
            .animation(HSMotion.adaptiveSpringSnap, value: configuration.isPressed)
    }
}

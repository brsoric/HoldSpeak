import SwiftUI

enum HSToastVariant {
    case success
    case warning
    case error
    case info

    var duration: TimeInterval {
        switch self {
        case .success: return HSToastToken.durationSuccess
        case .warning: return HSToastToken.durationWarning
        case .error:   return HSToastToken.durationError
        case .info:    return HSToastToken.durationWarning
        }
    }
}

struct HSToastView: View {
    let message: String
    let variant: HSToastVariant
    @State private var appeared = false

    var body: some View {
        HStack(spacing: HSToastToken.iconGap) {
            Image(systemName: iconName)
                .font(.system(size: HSToastToken.iconSize, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(message)
                .font(HSToastToken.font)
                .foregroundStyle(.primary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, HSToastToken.paddingH)
        .padding(.vertical, HSToastToken.paddingV)
        .frame(width: HSToastToken.width)
        .background(
            RoundedRectangle(cornerRadius: HSToastToken.radius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: HSToastToken.radius, style: .continuous)
                        .stroke(.white.opacity(HSToastToken.borderOpacity))
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .offset(y: appeared ? 0 : -HSToastToken.slideDistance)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(HSMotion.adaptiveSpringSmooth) { appeared = true }
        }
        .accessibilityLabel("\(variantLabel): \(message)")
    }

    private var iconName: String {
        switch variant {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch variant {
        case .success: return .hs_success
        case .warning: return .hs_warning
        case .error:   return .hs_error
        case .info:    return .hs_processing
        }
    }

    private var variantLabel: String {
        switch variant {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error:   return "Error"
        case .info:    return "Info"
        }
    }
}

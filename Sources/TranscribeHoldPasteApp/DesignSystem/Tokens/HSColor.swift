import SwiftUI

// MARK: - Layer 1: Primitive Color Tokens

extension Color {
    // Neutral scale
    static let hs_neutral_0   = Color(white: 1.00)
    static let hs_neutral_50  = Color(white: 0.98)
    static let hs_neutral_100 = Color(white: 0.96)
    static let hs_neutral_200 = Color(white: 0.90)
    static let hs_neutral_300 = Color(white: 0.82)
    static let hs_neutral_400 = Color(white: 0.64)
    static let hs_neutral_500 = Color(white: 0.45)
    static let hs_neutral_600 = Color(white: 0.32)
    static let hs_neutral_700 = Color(white: 0.25)
    static let hs_neutral_800 = Color(white: 0.15)
    static let hs_neutral_850 = Color(white: 0.11)
    static let hs_neutral_900 = Color(white: 0.07)
    static let hs_neutral_950 = Color(white: 0.04)

    // Red scale (recording, destructive)
    static let hs_red_400 = Color(red: 0.97, green: 0.40, blue: 0.40)
    static let hs_red_500 = Color(red: 0.94, green: 0.27, blue: 0.27)
    static let hs_red_600 = Color(red: 0.86, green: 0.15, blue: 0.15)

    // Blue scale (processing, accent)
    static let hs_blue_400 = Color(red: 0.38, green: 0.65, blue: 0.98)
    static let hs_blue_500 = Color(red: 0.23, green: 0.51, blue: 0.97)
    static let hs_blue_600 = Color(red: 0.15, green: 0.39, blue: 0.92)

    // Green scale (success)
    static let hs_green_400 = Color(red: 0.29, green: 0.78, blue: 0.42)
    static let hs_green_500 = Color(red: 0.13, green: 0.69, blue: 0.30)

    // Amber scale (warning)
    static let hs_amber_400 = Color(red: 0.98, green: 0.74, blue: 0.18)
    static let hs_amber_500 = Color(red: 0.96, green: 0.62, blue: 0.04)

    // Violet scale (AI/sparkle)
    static let hs_violet_400 = Color(red: 0.65, green: 0.46, blue: 0.98)
    static let hs_violet_500 = Color(red: 0.55, green: 0.33, blue: 0.97)
}

// MARK: - Layer 2: Semantic Color Tokens

extension Color {
    // Surface
    static let hs_surface_primary     = Color(nsColor: .windowBackgroundColor)
    static let hs_surface_secondary   = Color(nsColor: .controlBackgroundColor)
    static let hs_surface_elevated    = Color(nsColor: .underPageBackgroundColor)
    static let hs_surface_glass       = Color.white.opacity(0.06)

    // Text
    static let hs_text_primary   = Color(nsColor: .labelColor)
    static let hs_text_secondary = Color(nsColor: .secondaryLabelColor)
    static let hs_text_tertiary  = Color(nsColor: .tertiaryLabelColor)
    static let hs_text_disabled  = Color(nsColor: .quaternaryLabelColor)

    // State colors
    static let hs_recording    = hs_red_500
    static let hs_processing   = hs_blue_500
    static let hs_success      = hs_green_500
    static let hs_warning      = hs_amber_500
    static let hs_error        = hs_red_600
    static let hs_ai_accent    = hs_violet_500

    // Interactive
    static let hs_interactive         = Color.accentColor
    static let hs_interactive_hover   = Color.accentColor.opacity(0.85)
    static let hs_interactive_pressed = Color.accentColor.opacity(0.70)
    static let hs_interactive_muted   = Color.accentColor.opacity(0.15)

    // Border
    static let hs_border_default  = Color(nsColor: .separatorColor)
    static let hs_border_subtle   = Color.white.opacity(0.08)
    static let hs_border_focus    = Color.accentColor
    static let hs_border_error    = hs_red_500

    // Fills
    static let hs_fill_recording_bg    = hs_red_500.opacity(0.10)
    static let hs_fill_processing_bg   = hs_blue_500.opacity(0.10)
    static let hs_fill_success_bg      = hs_green_500.opacity(0.10)
    static let hs_fill_warning_bg      = hs_amber_500.opacity(0.10)
    static let hs_fill_error_bg        = hs_red_500.opacity(0.10)
    static let hs_fill_ai_bg           = hs_violet_500.opacity(0.10)
}

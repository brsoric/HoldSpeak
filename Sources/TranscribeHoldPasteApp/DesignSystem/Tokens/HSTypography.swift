import SwiftUI

// MARK: - Layer 1: Primitives

enum HSFontSize: CGFloat {
    case xxs  = 10
    case xs   = 11
    case sm   = 12
    case base = 13
    case md   = 14
    case lg   = 16
    case xl   = 18
    case xxl  = 20
    case xxxl = 24
}

// MARK: - Layer 2: Semantic Typography

extension Font {
    // Headings
    static let hs_heading_lg = Font.system(size: HSFontSize.xxl.rawValue, weight: .bold, design: .default)
    static let hs_heading_md = Font.system(size: HSFontSize.lg.rawValue, weight: .semibold, design: .default)
    static let hs_heading_sm = Font.system(size: HSFontSize.md.rawValue, weight: .semibold, design: .default)

    // Body
    static let hs_body      = Font.system(size: HSFontSize.base.rawValue, weight: .regular, design: .default)
    static let hs_body_bold = Font.system(size: HSFontSize.base.rawValue, weight: .medium, design: .default)

    // UI
    static let hs_label     = Font.system(size: HSFontSize.sm.rawValue, weight: .medium, design: .default)
    static let hs_caption   = Font.system(size: HSFontSize.xs.rawValue, weight: .regular, design: .default)
    static let hs_tiny      = Font.system(size: HSFontSize.xxs.rawValue, weight: .regular, design: .default)

    // Special
    static let hs_mono      = Font.system(size: HSFontSize.base.rawValue, weight: .regular, design: .monospaced)
    static let hs_mono_sm   = Font.system(size: HSFontSize.sm.rawValue, weight: .regular, design: .monospaced)
    static let hs_key_cap   = Font.system(size: HSFontSize.xs.rawValue, weight: .medium, design: .rounded)

    // Status
    static let hs_status    = Font.system(size: HSFontSize.sm.rawValue, weight: .medium, design: .default)
}

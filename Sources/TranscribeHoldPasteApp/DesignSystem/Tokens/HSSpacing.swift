import SwiftUI

// MARK: - Layer 1: Spacing Primitives (8pt grid)

enum HSSpace: CGFloat {
    case xxxs = 2
    case xxs  = 4
    case xs   = 6
    case sm   = 8
    case md   = 12
    case base = 16
    case lg   = 20
    case xl   = 24
    case xxl  = 32
    case xxxl = 48
}

// MARK: - Layer 2: Semantic Layout

enum HSLayout {
    // Padding
    static let paddingInline:     CGFloat = HSSpace.sm.rawValue
    static let paddingBlock:      CGFloat = HSSpace.xs.rawValue
    static let paddingCard:       CGFloat = HSSpace.md.rawValue
    static let paddingSection:    CGFloat = HSSpace.base.rawValue
    static let paddingPanel:      CGFloat = HSSpace.lg.rawValue

    // Gaps
    static let gapInline:         CGFloat = HSSpace.xxs.rawValue
    static let gapSmall:          CGFloat = HSSpace.xs.rawValue
    static let gapMedium:         CGFloat = HSSpace.sm.rawValue
    static let gapLarge:          CGFloat = HSSpace.md.rawValue
    static let gapSection:        CGFloat = HSSpace.base.rawValue
    static let gapPage:           CGFloat = HSSpace.xl.rawValue

    // Sizes
    static let iconSm:            CGFloat = 14
    static let iconMd:            CGFloat = 16
    static let iconLg:            CGFloat = 20
    static let statusDotSize:     CGFloat = 8
    static let menuBarDropdownW:  CGFloat = 300
    static let settingsMinW:      CGFloat = 640
    static let settingsMinH:      CGFloat = 520
    static let settingsDefaultW:  CGFloat = 680
    static let settingsDefaultH:  CGFloat = 560
    static let toastW:            CGFloat = 360
    static let toastH:            CGFloat = 84
}

import SwiftUI

// MARK: - Shared App State

enum HSAppState: Equatable {
    case loading
    case ready
    case recording
    case transcribing
    case error
}

enum HSModelState: Equatable {
    case loading
    case ready
    case error(String)
}

// MARK: - Button Tokens

enum HSButtonToken {
    static let heightSm:       CGFloat = 24
    static let heightMd:       CGFloat = 30
    static let heightLg:       CGFloat = 36
    static let paddingH:       CGFloat = HSSpace.md.rawValue
    static let paddingV:       CGFloat = HSSpace.xs.rawValue
    static let radius:         CGFloat = HSRadius.md.rawValue
    static let iconGap:        CGFloat = HSSpace.xxs.rawValue
    static let font:           Font    = .hs_label
    static let scalePressed:   CGFloat = 0.97
}

// MARK: - Toast Tokens

enum HSToastToken {
    static let width:          CGFloat = 360
    static let minHeight:      CGFloat = 44
    static let radius:         CGFloat = HSRadius.xl.rawValue
    static let paddingH:       CGFloat = HSSpace.md.rawValue
    static let paddingV:       CGFloat = HSSpace.sm.rawValue
    static let iconSize:       CGFloat = HSLayout.iconMd
    static let iconGap:        CGFloat = HSSpace.sm.rawValue
    static let borderOpacity:  Double  = 0.10
    static let durationSuccess: TimeInterval = 2.5
    static let durationWarning: TimeInterval = 3.5
    static let durationError:   TimeInterval = 5.0
    static let slideDistance:  CGFloat = 20
    static let font:           Font    = .hs_label
}

// MARK: - Card Tokens

enum HSCardToken {
    static let radius:         CGFloat = HSRadius.lg.rawValue
    static let padding:        CGFloat = HSSpace.md.rawValue
    static let gap:            CGFloat = HSSpace.xs.rawValue
    static let borderOpacity:  Double  = 0.06
    static let hoverScale:     CGFloat = 1.01
    static let hoverShadow:    HSShadowToken = HSShadow.sm
}

// MARK: - Shortcut Tokens

enum HSShortcutToken {
    static let height:         CGFloat = 36
    static let radius:         CGFloat = HSRadius.md.rawValue
    static let keyCapSize:     CGFloat = 22
    static let keyCapRadius:   CGFloat = HSRadius.xs.rawValue
    static let keyCapGap:      CGFloat = HSSpace.xxxs.rawValue
    static let recordingBorder = Color.hs_interactive
    static let idleBorder      = Color.hs_border_default
}

// MARK: - Waveform Tokens

enum HSWaveformToken {
    static let barCount:       Int     = 28
    static let barWidth:       CGFloat = 3
    static let barGap:         CGFloat = 2
    static let barRadius:      CGFloat = HSRadius.xs.rawValue
    static let minBarHeight:   CGFloat = 4
    static let maxBarHeight:   CGFloat = 32
    static let colorActive:    Color   = .hs_recording
    static let colorIdle:      Color   = .hs_text_tertiary
}

// MARK: - Status Dot Tokens

enum HSStatusDotToken {
    static let size:           CGFloat = 8
    static let pulseScale:     CGFloat = 2.2
    static let pulseOpacity:   Double  = 0.0

    static func color(for state: HSAppState) -> Color {
        switch state {
        case .loading:      return .hs_amber_500
        case .ready:        return .hs_success
        case .recording:    return .hs_recording
        case .transcribing: return .hs_processing
        case .error:        return .hs_error
        }
    }
}

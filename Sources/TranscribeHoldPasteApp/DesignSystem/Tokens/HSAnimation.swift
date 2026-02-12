import SwiftUI

enum HSMotion {
    // Durations
    static let instant:  Double = 0.08
    static let fast:     Double = 0.15
    static let normal:   Double = 0.30
    static let slow:     Double = 0.50
    static let gentle:   Double = 0.80

    // Spring presets
    static let springSnap   = Animation.spring(duration: 0.25, bounce: 0.1)
    static let springSmooth = Animation.spring(duration: 0.40, bounce: 0.15)
    static let springBounce = Animation.spring(duration: 0.60, bounce: 0.25)
    static let springGentle = Animation.spring(duration: 0.80, bounce: 0.20)

    // Easing
    static let easeOut = Animation.easeOut(duration: fast)
    static let easeInOut = Animation.easeInOut(duration: normal)

    // Pulse (recording)
    static let pulseInterval: Double = 1.2
    static let pulseDuration: Double = 0.6

    // Waveform
    static let waveformFPS: Double = 1.0 / 24.0
    static let waveformSpring = Animation.spring(duration: 0.08, bounce: 0)

    // Reduced motion support
    static var prefersReducedMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    static var adaptiveSpringSnap: Animation {
        prefersReducedMotion ? .linear(duration: 0.01) : springSnap
    }

    static var adaptiveSpringSmooth: Animation {
        prefersReducedMotion ? .linear(duration: 0.01) : springSmooth
    }
}

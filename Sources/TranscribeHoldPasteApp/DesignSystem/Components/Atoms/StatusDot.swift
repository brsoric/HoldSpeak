import SwiftUI

struct StatusDot: View {
    let state: HSAppState
    @State private var isPulsing = false

    private var shouldPulse: Bool {
        state == .recording || state == .transcribing || state == .loading
    }

    var body: some View {
        ZStack {
            if shouldPulse {
                Circle()
                    .fill(HSStatusDotToken.color(for: state).opacity(0.35))
                    .frame(width: HSStatusDotToken.size, height: HSStatusDotToken.size)
                    .scaleEffect(isPulsing ? HSStatusDotToken.pulseScale : 1.0)
                    .opacity(isPulsing ? HSStatusDotToken.pulseOpacity : 0.35)
            }
            Circle()
                .fill(HSStatusDotToken.color(for: state))
                .frame(width: HSStatusDotToken.size, height: HSStatusDotToken.size)
        }
        .accessibilityLabel(accessibilityText)
        .onAppear { if shouldPulse { startPulse() } }
        .onChange(of: state) { _ in
            if shouldPulse {
                startPulse()
            } else {
                isPulsing = false
            }
        }
        .animation(HSMotion.adaptiveSpringSmooth, value: state)
    }

    private func startPulse() {
        guard !HSMotion.prefersReducedMotion else { return }
        withAnimation(.easeInOut(duration: HSMotion.pulseDuration).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }

    private var accessibilityText: String {
        switch state {
        case .loading:      return "Loading"
        case .ready:        return "Ready"
        case .recording:    return "Recording in progress"
        case .transcribing: return "Transcribing"
        case .error:        return "Error"
        }
    }
}

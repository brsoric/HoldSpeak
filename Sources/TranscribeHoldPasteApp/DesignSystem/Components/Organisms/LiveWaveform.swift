import SwiftUI

struct LiveWaveform: View {
    let isActive: Bool
    @Binding var amplitudes: [CGFloat]

    var body: some View {
        HStack(alignment: .center, spacing: HSWaveformToken.barGap) {
            ForEach(0..<HSWaveformToken.barCount, id: \.self) { index in
                WaveformBar(
                    amplitude: index < amplitudes.count ? amplitudes[index] : 0,
                    isActive: isActive
                )
            }
        }
        .frame(height: HSWaveformToken.maxBarHeight)
        .padding(.horizontal, HSSpace.sm.rawValue)
        .padding(.vertical, HSSpace.xs.rawValue)
        .background(
            RoundedRectangle(cornerRadius: HSRadius.md.rawValue, style: .continuous)
                .fill(isActive ? Color.hs_fill_recording_bg : .clear)
        )
        .animation(HSMotion.adaptiveSpringSmooth, value: isActive)
        .accessibilityLabel(isActive ? "Audio waveform, recording" : "Audio waveform, idle")
    }
}

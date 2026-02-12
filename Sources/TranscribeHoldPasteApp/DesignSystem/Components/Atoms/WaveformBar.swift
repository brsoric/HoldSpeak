import SwiftUI

struct WaveformBar: View {
    let amplitude: CGFloat
    let isActive: Bool

    private var height: CGFloat {
        HSWaveformToken.minBarHeight +
        (amplitude * (HSWaveformToken.maxBarHeight - HSWaveformToken.minBarHeight))
    }

    var body: some View {
        RoundedRectangle(cornerRadius: HSWaveformToken.barRadius)
            .fill(isActive ? HSWaveformToken.colorActive : HSWaveformToken.colorIdle)
            .frame(width: HSWaveformToken.barWidth, height: height)
            .animation(HSMotion.waveformSpring, value: amplitude)
    }
}

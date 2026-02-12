import SwiftUI

struct HSShadowToken {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum HSShadow {
    static let none = HSShadowToken(color: .clear, radius: 0, x: 0, y: 0)
    static let sm = HSShadowToken(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    static let md = HSShadowToken(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 2)
    static let lg = HSShadowToken(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 4)
    static let glow_red = HSShadowToken(color: Color.hs_red_500.opacity(0.40), radius: 12, x: 0, y: 0)
    static let glow_blue = HSShadowToken(color: Color.hs_blue_500.opacity(0.30), radius: 12, x: 0, y: 0)
    static let glow_violet = HSShadowToken(color: Color.hs_violet_500.opacity(0.30), radius: 12, x: 0, y: 0)
}

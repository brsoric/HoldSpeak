import AppKit
import SwiftUI

@MainActor
final class ToastWindowController {
    private let panel: NSPanel
    private var dismissWorkItem: DispatchWorkItem?

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: HSLayout.toastW, height: HSLayout.toastH),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]

        self.panel = panel
    }

    func show(message: String, variant: HSToastVariant = .info, durationSeconds: TimeInterval = 3.0) {
        dismissWorkItem?.cancel()

        let view = HSToastView(message: message, variant: variant)
        panel.contentView = NSHostingView(rootView: view)

        positionTopRight()
        panel.orderFrontRegardless()

        let item = DispatchWorkItem { [weak self] in
            self?.panel.orderOut(nil)
        }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + durationSeconds, execute: item)
    }

    private func positionTopRight() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let margin: CGFloat = HSLayout.paddingSection
        let origin = CGPoint(
            x: visible.maxX - size.width - margin,
            y: visible.maxY - size.height - margin
        )
        panel.setFrameOrigin(origin)
    }
}

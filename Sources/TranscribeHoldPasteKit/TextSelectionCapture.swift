import Foundation
import AppKit
import Carbon.HIToolbox
import os
@preconcurrency import ApplicationServices

private let logger = Logger(subsystem: "com.holdspeak.app", category: "TextSelection")

/// Utility for capturing selected text from the focused application.
/// Uses hybrid approach: AX APIs for native apps, clipboard fallback for web apps.
public enum TextSelectionCapture {
    /// Attempts to capture the currently selected text from the focused application.
    /// Uses a hybrid approach: tries AX API first (fast), falls back to clipboard method if needed (universal).
    /// - Parameter withFallback: Whether to use clipboard fallback if AX API fails (default: true)
    /// - Returns: The selected text, or nil if unavailable (no selection, no permission, etc.)
    /// - Note: Can be called from any thread - both AX APIs and clipboard access are thread-safe
    public static func captureSelectedText(withFallback: Bool = true) -> String? {
        // Try AX API first (fast path for native apps)
        if let text = captureViaAccessibilityAPI() {
            logger.debug("Captured via AX API")
            return text
        }

        // Fallback to clipboard method (works in web apps)
        if withFallback {
            if let text = captureViaClipboard() {
                logger.debug("Captured via clipboard fallback")
                return text
            }
        }

        logger.debug("No context captured")
        return nil
    }

    /// Captures selected text via Accessibility API (fast, works in native apps).
    private static func captureViaAccessibilityAPI() -> String? {
        // Return nil if accessibility not trusted (graceful fallback)
        guard AXIsProcessTrusted() else {
            return nil
        }

        // Get system-wide accessibility element
        let systemWide = AXUIElementCreateSystemWide()

        // Get the focused UI element
        var focusedElement: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success,
              let element = focusedElement else {
            return nil
        }

        // Try to get selected text attribute
        // CFTypeRef from AXUIElementCopyAttributeValue is always bridgeable to AXUIElement
        let axElement = element as! AXUIElement  // Safe: AX API guarantees this type
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            axElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard textResult == .success,
              let text = selectedText as? String,
              !text.isEmpty else {
            return nil
        }

        return text
    }

    /// Captures selected text via clipboard (universal, works in all apps including web).
    /// Temporarily copies selection to clipboard, reads it, then restores original clipboard.
    private static func captureViaClipboard() -> String? {
        // Check accessibility permission (needed to post Cmd+C)
        guard AXIsProcessTrusted() else {
            return nil
        }

        let inserter = ClipboardInserter()

        // 1. Snapshot current clipboard
        let originalClipboard = inserter.snapshot()

        // 2. Post Cmd+C to copy selection
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return nil
        }

        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: true
        )
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: false
        )
        keyUp?.flags = .maskCommand

        guard let keyDown, let keyUp else {
            return nil
        }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        // 3. Wait for system to process the synthetic Cmd+C keystroke.
        // Thread.sleep is intentional: this is a synchronous fallback path (AX API is tried first),
        // 100ms is the minimum reliable delay for clipboard to update across all app types.
        Thread.sleep(forTimeInterval: 0.1)

        // 4. Read clipboard
        let text = NSPasteboard.general.string(forType: .string)

        // 5. Restore original clipboard
        inserter.restore(originalClipboard)

        // 6. Return captured text (or nil if empty)
        return (text?.isEmpty == false) ? text : nil
    }
}

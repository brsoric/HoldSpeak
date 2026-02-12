import CoreGraphics
import Foundation
import os

private let logger = Logger(subsystem: "com.holdspeak.app", category: "HotkeyConfig")

public struct HotkeyConfig: Codable, Equatable, Sendable {
    public var transcriptKeyCode: UInt16
    public var transcriptModifiers: UInt32
    public var promptedKeyCode: UInt16
    public var promptedModifiers: UInt32

    public init(
        transcriptKeyCode: UInt16 = 49,   // kVK_Space
        transcriptModifiers: UInt32 = 0x0900, // controlKey | optionKey
        promptedKeyCode: UInt16 = 49,     // kVK_Space
        promptedModifiers: UInt32 = 0x0D00  // controlKey | optionKey | cmdKey
    ) {
        self.transcriptKeyCode = transcriptKeyCode
        self.transcriptModifiers = transcriptModifiers
        self.promptedKeyCode = promptedKeyCode
        self.promptedModifiers = promptedModifiers
    }

    public static let `default` = HotkeyConfig()

    private static let userDefaultsKey = "hotkey_config_v1"

    public static func load() -> HotkeyConfig {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(HotkeyConfig.self, from: data)
        } catch {
            logger.error("Failed to decode hotkey config: \(error.localizedDescription, privacy: .public)")
            return .default
        }
    }

    public func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: HotkeyConfig.userDefaultsKey)
        } catch {
            logger.error("Failed to encode hotkey config: \(error.localizedDescription, privacy: .public)")
        }
    }

    public var transcriptDescription: String {
        modifierString(transcriptModifiers) + keyString(transcriptKeyCode)
    }

    public var promptedDescription: String {
        modifierString(promptedModifiers) + keyString(promptedKeyCode)
    }

    public var transcriptModifierLabels: [String] {
        modifierLabels(transcriptModifiers)
    }

    public var promptedModifierLabels: [String] {
        modifierLabels(promptedModifiers)
    }

    public var transcriptKeyLabel: String {
        keyString(transcriptKeyCode)
    }

    public var promptedKeyLabel: String {
        keyString(promptedKeyCode)
    }

    public func transcriptHotkey() -> PressAndHoldHotkeyMonitor.Hotkey {
        PressAndHoldHotkeyMonitor.Hotkey(
            requiredFlags: cgEventFlags(from: transcriptModifiers),
            keyCode: CGKeyCode(transcriptKeyCode)
        )
    }

    public func promptedHotkey() -> PressAndHoldHotkeyMonitor.Hotkey {
        PressAndHoldHotkeyMonitor.Hotkey(
            requiredFlags: cgEventFlags(from: promptedModifiers),
            keyCode: CGKeyCode(promptedKeyCode)
        )
    }

    private func cgEventFlags(from carbonMods: UInt32) -> CGEventFlags {
        var flags: CGEventFlags = []
        if carbonMods & 0x0100 != 0 { flags.insert(.maskControl) }
        if carbonMods & 0x0200 != 0 { flags.insert(.maskShift) }
        if carbonMods & 0x0400 != 0 { flags.insert(.maskCommand) }
        if carbonMods & 0x0800 != 0 { flags.insert(.maskAlternate) }
        return flags
    }

    private func modifierLabels(_ mods: UInt32) -> [String] {
        var result: [String] = []
        if mods & 0x0100 != 0 { result.append("Ctrl") }   // controlKey
        if mods & 0x0800 != 0 { result.append("Opt") }    // optionKey
        if mods & 0x0200 != 0 { result.append("Shift") }  // shiftKey
        if mods & 0x0100 != 0 && mods & 0x0800 != 0 && mods & 0x0400 != 0 {
            // already added Ctrl and Opt, add Cmd
        }
        if mods & 0x0400 != 0 { result.append("Cmd") }    // cmdKey (0x0100 is control)
        return result
    }

    private func modifierString(_ mods: UInt32) -> String {
        modifierLabels(mods).joined(separator: "+")
    }

    private func keyString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Esc"
        case 76: return "Enter"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key(\(keyCode))"
        }
    }
}

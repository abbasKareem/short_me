import AppKit
import Foundation

struct ShortcutModifiers: OptionSet, Hashable, Sendable {
    let rawValue: Int

    static let command = ShortcutModifiers(rawValue: 1 << 0)
    static let shift = ShortcutModifiers(rawValue: 1 << 1)
    static let option = ShortcutModifiers(rawValue: 1 << 2)
    static let control = ShortcutModifiers(rawValue: 1 << 3)
    static let function = ShortcutModifiers(rawValue: 1 << 4)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(eventFlags: NSEvent.ModifierFlags) {
        var result: ShortcutModifiers = []
        let flags = eventFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.function) { result.insert(.function) }
        self = result
    }
}

enum KeyboardShortcutFormatter {
    static func displayString(key: String, modifiersRawValue: Int) -> String {
        displayString(key: key, modifiers: ShortcutModifiers(rawValue: modifiersRawValue))
    }

    static func displayString(key: String, modifiers: ShortcutModifiers) -> String {
        guard !key.isEmpty else { return "" }

        var result = ""
        if modifiers.contains(.function) { result += "fn" }
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.command) { result += "⌘" }
        return result + displayKey(key)
    }

    static func accessibilityString(key: String, modifiers: ShortcutModifiers) -> String {
        guard !key.isEmpty else { return "not set" }
        var parts: [String] = []
        if modifiers.contains(.function) { parts.append("Function") }
        if modifiers.contains(.control) { parts.append("Control") }
        if modifiers.contains(.option) { parts.append("Option") }
        if modifiers.contains(.shift) { parts.append("Shift") }
        if modifiers.contains(.command) { parts.append("Command") }
        parts.append(accessibilityKey(key))
        return parts.joined(separator: " ")
    }

    static func normalizedKey(from event: NSEvent) -> String? {
        switch event.keyCode {
        case 36, 76: return "return"
        case 53: return "escape"
        case 48: return "tab"
        case 49: return "space"
        case 51: return "delete"
        case 117: return "forwardDelete"
        case 123: return "leftArrow"
        case 124: return "rightArrow"
        case 125: return "downArrow"
        case 126: return "upArrow"
        case 115: return "home"
        case 119: return "end"
        case 116: return "pageUp"
        case 121: return "pageDown"
        default:
            guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
                return nil
            }
            return characters.count == 1 ? characters.uppercased() : characters
        }
    }

    private static func displayKey(_ key: String) -> String {
        switch key {
        case "return": return "↩"
        case "escape": return "⎋"
        case "tab": return "⇥"
        case "space": return "Space"
        case "delete": return "⌫"
        case "forwardDelete": return "⌦"
        case "leftArrow": return "←"
        case "rightArrow": return "→"
        case "downArrow": return "↓"
        case "upArrow": return "↑"
        case "home": return "↖"
        case "end": return "↘"
        case "pageUp": return "⇞"
        case "pageDown": return "⇟"
        default: return key
        }
    }

    private static func accessibilityKey(_ key: String) -> String {
        switch key {
        case "return": return "Return"
        case "escape": return "Escape"
        case "tab": return "Tab"
        case "space": return "Space"
        case "delete": return "Delete"
        case "forwardDelete": return "Forward Delete"
        case "leftArrow": return "Left Arrow"
        case "rightArrow": return "Right Arrow"
        case "downArrow": return "Down Arrow"
        case "upArrow": return "Up Arrow"
        case "home": return "Home"
        case "end": return "End"
        case "pageUp": return "Page Up"
        case "pageDown": return "Page Down"
        default: return key
        }
    }
}

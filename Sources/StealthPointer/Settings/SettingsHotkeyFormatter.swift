import AppKit

enum SettingsHotkeyFormatter {
    static let keys: [Int: String] = [
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 49: "Space", 36: "Return", 48: "Tab", 53: "Escape", 51: "Delete",
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J", 40: "K",
        37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U",
        9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z"
    ]
    static func string(keyCode: Int, modifiers: Int) -> String {
        var parts: [String] = []
        if modifiers & 0x100 != 0 { parts.append("Cmd") }
        if modifiers & 0x1000 != 0 { parts.append("Ctrl") }
        if modifiers & 0x800 != 0 { parts.append("Alt") }
        if modifiers & 0x200 != 0 { parts.append("Shift") }
        parts.append(keys[keyCode] ?? "Key \(keyCode)")
        return parts.joined(separator: "+")
    }
    static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> Int {
        var result = 0
        if flags.contains(.command) { result |= 0x100 }
        if flags.contains(.control) { result |= 0x1000 }
        if flags.contains(.option) { result |= 0x800 }
        if flags.contains(.shift) { result |= 0x200 }
        return result
    }
}

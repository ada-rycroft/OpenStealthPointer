import Foundation

struct SavedGameProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var showKeys: String
    var hideKeys: String
}

enum ProfileMode: String, CaseIterable, Identifiable {
    case action = "Action"
    case strategy = "Strategy"
    case ownGames = "Own Games"
    var id: String { rawValue }
}

enum GameProfileRules {
    static let actionShow = "Escape, Tab, B, C, I, J, K, M, O, P"
    static let actionHide = "W, A, S, D, Q, E, Space, Shift"
    static let strategyShow = "Escape, Tab, M, P, B"
    static let strategyHide = "Space, Return"

    static func decode(_ string: String) -> [SavedGameProfile] {
        guard let data = string.data(using: .utf8),
              let profiles = try? JSONDecoder().decode([SavedGameProfile].self, from: data) else { return [] }
        return profiles
    }

    static func encode(_ profiles: [SavedGameProfile]) -> String {
        guard let data = try? JSONEncoder().encode(profiles),
              let string = String(data: data, encoding: .utf8) else { return "[]" }
        return string
    }

    static func saving(name: String, selectedProfile: String, showKeys: String, hideKeys: String,
                       in profiles: [SavedGameProfile]) -> (profile: SavedGameProfile, profiles: [SavedGameProfile]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = trimmed.isEmpty ? (selectedProfile == "Own Games" ? "Own Game" : selectedProfile) : trimmed
        let profile = SavedGameProfile(id: UUID(), name: resolved, showKeys: showKeys, hideKeys: hideKeys)
        var result = profiles.filter { $0.name.caseInsensitiveCompare(resolved) != .orderedSame }
        result.append(profile)
        result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return (profile, result)
    }
}

enum ProfileKeyboardTokens {
    static let aliases: [String: String] = [
        "Esc": "Escape", "Enter": "Return", "Ctrl": "Control", "Cmd": "Command",
        "`": "Grave", "-": "Minus", "=": "Equal", "[": "LeftBracket", "]": "RightBracket",
        ";": "Semicolon", "'": "Quote", ",": "Comma", ".": "Period", "/": "Slash", "\\": "Backslash",
        "Del": "ForwardDelete", "Clear": "KeypadClear", "PrtScr": "F13", "ScrLk": "F14", "Pause": "F15",
        "AltGr": "RightOption", "Num/": "KeypadDivide", "Num*": "KeypadMultiply", "Num-": "KeypadMinus",
        "Num+": "KeypadPlus", "NumEnter": "KeypadEnter", "Num.": "KeypadDecimal",
        "Num0": "Keypad0", "Num1": "Keypad1", "Num2": "Keypad2", "Num3": "Keypad3", "Num4": "Keypad4",
        "Num5": "Keypad5", "Num6": "Keypad6", "Num7": "Keypad7", "Num8": "Keypad8", "Num9": "Keypad9"
    ]
    static func canonical(_ label: String) -> String { aliases[label] ?? label }
    static func split(_ rules: String) -> [String] {
        rules.components(separatedBy: CharacterSet(charactersIn: ",;\n\t"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    static func contains(_ label: String, in rules: String) -> Bool {
        let token = canonical(label)
        return split(rules).contains { $0.caseInsensitiveCompare(token) == .orderedSame }
    }
    static func toggle(_ label: String, in rules: String) -> String {
        let token = canonical(label)
        var tokens = split(rules)
        if let index = tokens.firstIndex(where: { $0.caseInsensitiveCompare(token) == .orderedSame }) {
            tokens.remove(at: index)
        } else { tokens.append(token) }
        return tokens.joined(separator: ", ")
    }
}

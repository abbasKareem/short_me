import Foundation

enum ShortcutSearch {
    static func matches(name: String, key: String, modifiersRawValue: Int, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }
        let display = KeyboardShortcutFormatter.displayString(
            key: key,
            modifiersRawValue: modifiersRawValue
        )
        return name.localizedCaseInsensitiveContains(trimmedQuery)
            || display.localizedCaseInsensitiveContains(trimmedQuery)
    }
}

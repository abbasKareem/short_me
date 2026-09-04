import SwiftUI

struct ShortcutKeyView: View {
    let key: String
    let modifiersRawValue: Int

    var body: some View {
        Text(KeyboardShortcutFormatter.displayString(key: key, modifiersRawValue: modifiersRawValue))
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(
                "Keyboard shortcut, \(KeyboardShortcutFormatter.accessibilityString(key: key, modifiers: ShortcutModifiers(rawValue: modifiersRawValue)))"
            )
    }
}

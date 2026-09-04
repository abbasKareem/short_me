import SwiftUI

struct ShortcutEditorRow: View {
    @Binding var draft: ShortcutDraft
    let showsShortcut: Bool
    let isSelected: Bool
    let select: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 24, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .accessibilityLabel("Delete \(draft.name.isEmpty ? "item" : draft.name)")

            TextField("Shortcut name", text: $draft.name)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Shortcut name")
            if showsShortcut {
                ShortcutRecorderView(key: $draft.key, modifiers: $draft.modifiers)
                    .frame(width: 150, height: 30)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }
}

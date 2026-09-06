import SwiftUI

struct ShortcutRowView: View {
    @Binding var draft: ShortcutDraft
    let showsShortcut: Bool
    let isHighlighted: Bool
    let focusedItem: FocusState<UUID?>.Binding
    let highlight: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 24, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .accessibilityLabel("Delete \(draft.name.isEmpty ? "item" : draft.name)")

            TextField("Item name", text: $draft.name, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)
                .focused(focusedItem, equals: draft.id)
                .accessibilityLabel("Item name")

            Spacer(minLength: 12)

            if showsShortcut {
                ShortcutRecorderView(key: $draft.key, modifiers: $draft.modifiers)
                    .frame(width: 64, height: 28)
                    .overlay {
                        if draft.key.isEmpty {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.red.opacity(0.8), lineWidth: 1)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 47)
        .contentShape(Rectangle())
        .background(isHighlighted ? Color.accentColor.opacity(0.18) : Color.clear)
        .simultaneousGesture(TapGesture().onEnded(highlight))
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
    }
}

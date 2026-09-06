import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Keyboard Shortcuts")
                .font(.title2.weight(.semibold))

            Text("Use Shortme without leaving the keyboard.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .padding(.bottom, 18)

            VStack(spacing: 0) {
                ShortcutInfoRow(
                    keys: ["⌘", "⇧", "X"],
                    title: "Show, focus, or close the panel",
                    detail: "Opens the group list when hidden, focuses the current view when unfocused, and closes it when already focused."
                )

                Divider()

                ShortcutInfoRow(
                    keys: ["↑", "↓"],
                    title: "Move the highlight",
                    detail: "Cycles through the available groups or items."
                )

                Divider()

                ShortcutInfoRow(
                    keys: ["↩"],
                    title: "Open or select",
                    detail: "Opens a highlighted group or selects all text in a highlighted item."
                )

                Divider()

                ShortcutInfoRow(
                    keys: ["⌘", "+"],
                    title: "Add an item",
                    detail: "Creates and focuses a new item while a group is open."
                )

                Divider()

                ShortcutInfoRow(
                    keys: ["⌘", "C"],
                    title: "Copy item text",
                    detail: "Copies the item text after selecting it with Return."
                )

                Divider()

                ShortcutInfoRow(
                    keys: ["esc"],
                    title: "Go back or close",
                    detail: "Returns to the group list, or closes the panel from the group list."
                )
            }
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.separator.opacity(0.6), lineWidth: 0.5)
            }
        }
        .padding(24)
        .frame(width: 540)
    }
}

private struct ShortcutInfoRow: View {
    let keys: [String]
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            HStack(spacing: 4) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                    Text(key)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .frame(minWidth: 20, minHeight: 20)
                        .padding(.horizontal, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.separator.opacity(0.7), lineWidth: 0.5)
                        }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(keys.joined(separator: " "))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

import SwiftUI

struct GroupRowView: View {
    let group: ShortcutGroup
    let open: () -> Void
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: open) {
                HStack {
                    Text(group.name)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding(.leading, 16)
                .padding(.trailing, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 51)
            }
            .buttonStyle(.plain)

            Button(action: edit) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 40, height: 51)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Edit \(group.name)")
        }
    }
}

import SwiftUI

struct GroupListView: View {
    let groups: [ShortcutGroup]
    let openGroup: (UUID) -> Void
    let editGroup: (UUID) -> Void
    let manageGroups: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Shortcuts")
                    .font(.system(size: 14, weight: .semibold))
                HStack {
                    Spacer()
                    Button(action: manageGroups) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Manage Groups")
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 50)

            Divider()

            if groups.isEmpty {
                EmptyStateView(
                    title: "No groups",
                    detail: "Create a group to organize your shortcuts.",
                    buttonTitle: "Manage Groups",
                    action: manageGroups
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                            GroupRowView(
                                group: group,
                                open: { openGroup(group.id) },
                                edit: { editGroup(group.id) }
                            )
                            if index < groups.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
    }
}

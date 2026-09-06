import SwiftUI

struct GroupListView: View {
    let groups: [ShortcutGroup]
    @Binding var highlightedGroupID: UUID?
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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                                GroupRowView(
                                    group: group,
                                    isHighlighted: highlightedGroupID == group.id,
                                    open: {
                                        highlightedGroupID = group.id
                                        openGroup(group.id)
                                    },
                                    edit: { editGroup(group.id) }
                                )
                                .id(group.id)
                                if index < groups.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                    }
                    .onChange(of: highlightedGroupID) { _, groupID in
                        guard let groupID else { return }
                        withAnimation(.easeInOut(duration: 0.12)) {
                            proxy.scrollTo(groupID, anchor: .center)
                        }
                    }
                }
            }
        }
        .keyboardListNavigation(
            onMove: moveHighlight,
            onSubmit: openHighlightedGroup
        )
        .onAppear(perform: ensureValidHighlight)
        .onChange(of: groups.map(\.id)) { _, _ in
            ensureValidHighlight()
        }
    }

    private func ensureValidHighlight() {
        guard groups.contains(where: { $0.id == highlightedGroupID }) else {
            highlightedGroupID = groups.first?.id
            return
        }
    }

    private func moveHighlight(_ direction: KeyboardListNavigationDirection) {
        guard !groups.isEmpty else { return }

        guard let currentIndex = groups.firstIndex(where: { $0.id == highlightedGroupID }) else {
            highlightedGroupID = direction == .down ? groups.first?.id : groups.last?.id
            return
        }

        switch direction {
        case .up:
            let previousIndex = currentIndex == groups.startIndex
                ? groups.index(before: groups.endIndex)
                : groups.index(before: currentIndex)
            highlightedGroupID = groups[previousIndex].id
        case .down:
            let nextIndex = groups.index(after: currentIndex)
            highlightedGroupID = nextIndex == groups.endIndex
                ? groups.first?.id
                : groups[nextIndex].id
        }
    }

    private func openHighlightedGroup() {
        guard
            let highlightedGroupID,
            groups.contains(where: { $0.id == highlightedGroupID })
        else {
            return
        }
        openGroup(highlightedGroupID)
    }
}

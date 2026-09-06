import SwiftData
import SwiftUI

struct ShortcutPanelRootView: View {
    @Query(sort: [SortDescriptor(\ShortcutGroup.sortOrder), SortDescriptor(\ShortcutGroup.createdAt)])
    private var groups: [ShortcutGroup]
    @Bindable var appState: AppState
    let close: () -> Void
    let editGroup: (UUID) -> Void
    let manageGroups: () -> Void
    let preferredHeightChanged: (CGFloat) -> Void

    @State private var highlightedGroupID: UUID?
    @State private var highlightedItemID: UUID?

    private var selectedGroup: ShortcutGroup? {
        guard let selectedGroupID = appState.selectedGroupID else { return nil }
        return groups.first { $0.id == selectedGroupID }
    }

    private var preferredHeight: CGFloat {
        if let group = selectedGroup {
            let resultCount = group.shortcuts.filter {
                ShortcutSearch.matches(
                    name: $0.name,
                    key: $0.key,
                    modifiersRawValue: $0.modifiersRawValue,
                    query: appState.searchQuery
                )
            }.count
            return min(max(140 + CGFloat(resultCount) * 47, 240), 500)
        }
        return min(max(51 + CGFloat(groups.count) * 51, 180), 500)
    }

    var body: some View {
        Group {
            if let group = selectedGroup {
                ShortcutListView(
                    group: group,
                    searchQuery: $appState.searchQuery,
                    highlightedItemID: $highlightedItemID,
                    goBack: {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            appState.selectedGroupID = nil
                            appState.searchQuery = ""
                            highlightedItemID = nil
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                GroupListView(
                    groups: groups,
                    highlightedGroupID: $highlightedGroupID,
                    openGroup: { groupID in
                        withAnimation(.easeInOut(duration: 0.16)) {
                            highlightedGroupID = groupID
                            highlightedItemID = nil
                            appState.selectedGroupID = groupID
                        }
                    },
                    editGroup: editGroup,
                    manageGroups: manageGroups
                )
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .frame(width: 360, height: preferredHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.separator.opacity(0.5), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .onAppear { preferredHeightChanged(preferredHeight) }
        .onChange(of: appState.isShortcutPanelVisible) { _, isVisible in
            guard isVisible else { return }
            highlightedGroupID = groups.first?.id
            highlightedItemID = nil
        }
        .onChange(of: preferredHeight) { _, newHeight in
            preferredHeightChanged(newHeight)
        }
        .onChange(of: groups.map(\.id)) { _, _ in
            if appState.selectedGroupID != nil, selectedGroup == nil {
                appState.selectedGroupID = nil
                appState.searchQuery = ""
                highlightedItemID = nil
            }
        }
        .onExitCommand {
            if appState.selectedGroupID == nil {
                close()
            } else {
                appState.selectedGroupID = nil
                appState.searchQuery = ""
                highlightedItemID = nil
            }
        }
    }
}

import AppKit
import SwiftData
import SwiftUI

struct ShortcutListView: View {
    @Environment(\.modelContext) private var modelContext
    let group: ShortcutGroup
    @Binding var searchQuery: String
    let goBack: () -> Void

    @FocusState private var focusedItemID: UUID?
    @State private var drafts: [ShortcutDraft]
    @State private var errorMessage: String?

    init(group: ShortcutGroup, searchQuery: Binding<String>, goBack: @escaping () -> Void) {
        self.group = group
        _searchQuery = searchQuery
        self.goBack = goBack
        _drafts = State(initialValue: Self.makeDrafts(from: group))
    }

    private var filteredDrafts: [ShortcutDraft] {
        drafts.filter {
            ShortcutSearch.matches(
                name: $0.name,
                key: $0.key,
                modifiersRawValue: $0.modifiers.rawValue,
                query: searchQuery
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 28, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to Groups")

                Text(group.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Spacer()

                Button(action: addItem) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 30, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Item")
            }
            .padding(.horizontal, 10)
            .frame(height: 48)

            SearchField(text: $searchQuery)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)

            Divider()

            if drafts.isEmpty {
                EmptyStateView(
                    title: "No items",
                    detail: "Use + to add an item."
                )
            } else if filteredDrafts.isEmpty {
                EmptyStateView(title: "No items found")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredDrafts) { draft in
                            ShortcutRowView(
                                draft: draftBinding(for: draft),
                                showsShortcut: group.groupType == .shortcuts,
                                focusedItem: $focusedItemID,
                                delete: { deleteItem(id: draft.id) }
                            )
                            if draft.id != filteredDrafts.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
        .alert("Couldn’t Save Changes", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private func addItem() {
        searchQuery = ""
        let nextSortOrder = (drafts.map(\.sortOrder).max() ?? -1) + 1
        let draft = ShortcutDraft(sortOrder: nextSortOrder)
        drafts.insert(draft, at: 0)

        Task { @MainActor in
            focusedItemID = draft.id
        }
    }

    private func deleteItem(id: UUID) {
        NSApp.keyWindow?.makeFirstResponder(nil)
        if focusedItemID == id {
            focusedItemID = nil
        }
        drafts.removeAll { $0.id == id }

        guard let item = group.shortcuts.first(where: { $0.id == id }) else { return }
        modelContext.delete(item)
        saveContext(reloadOnFailure: true)
    }

    private func draftBinding(for fallback: ShortcutDraft) -> Binding<ShortcutDraft> {
        Binding(
            get: {
                drafts.first(where: { $0.id == fallback.id }) ?? fallback
            },
            set: { updatedDraft in
                guard let index = drafts.firstIndex(where: { $0.id == fallback.id }) else {
                    return
                }
                drafts[index] = updatedDraft
                persistIfValid(updatedDraft)
            }
        )
    }

    private func persistIfValid(_ draft: ShortcutDraft) {
        guard !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        if group.groupType == .shortcuts, draft.key.isEmpty {
            return
        }

        if let item = group.shortcuts.first(where: { $0.id == draft.id }) {
            item.name = draft.name
            item.key = draft.key
            item.modifiersRawValue = draft.modifiers.rawValue
            item.sortOrder = draft.sortOrder
        } else {
            let item = ShortcutItem(
                id: draft.id,
                name: draft.name,
                key: draft.key,
                modifiersRawValue: draft.modifiers.rawValue,
                sortOrder: draft.sortOrder
            )
            modelContext.insert(item)
            group.shortcuts.append(item)
        }
        saveContext(reloadOnFailure: true)
    }

    private func saveContext(reloadOnFailure: Bool) {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            if reloadOnFailure {
                drafts = Self.makeDrafts(from: group)
            }
        }
    }

    private static func makeDrafts(from group: ShortcutGroup) -> [ShortcutDraft] {
        group.shortcuts.sorted {
            if $0.createdAt == $1.createdAt { return $0.sortOrder > $1.sortOrder }
            return $0.createdAt > $1.createdAt
        }.map { item in
            ShortcutDraft(
                id: item.id,
                name: item.name,
                key: item.key,
                modifiers: ShortcutModifiers(rawValue: item.modifiersRawValue),
                sortOrder: item.sortOrder
            )
        }
    }
}

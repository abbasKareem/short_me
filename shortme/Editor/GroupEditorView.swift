import AppKit
import SwiftData
import SwiftUI

struct GroupEditorView: View {
    private let modelContext: ModelContext
    private let groupID: UUID
    private let groupType: ShortcutGroupType
    private let cancel: () -> Void

    @State private var groupName: String
    @State private var drafts: [ShortcutDraft]
    @State private var selectedID: UUID?
    @State private var errorMessage: String?
    @State private var saveToastID: UUID?

    init(
        group: ShortcutGroup,
        modelContext: ModelContext,
        cancel: @escaping () -> Void
    ) {
        self.modelContext = modelContext
        groupID = group.id
        groupType = group.groupType
        self.cancel = cancel
        _groupName = State(initialValue: group.name)
        _drafts = State(initialValue: group.shortcuts.sorted {
            $0.sortOrder < $1.sortOrder
        }.enumerated().map { index, item in
            ShortcutDraft(
                id: item.id,
                name: item.name,
                key: item.key,
                modifiers: ShortcutModifiers(rawValue: item.modifiersRawValue),
                sortOrder: index
            )
        })
    }

    private var validationMessage: String? {
        if groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Group name is required."
        }
        if drafts.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return "Item name is required."
        }
        if groupType == .shortcuts, drafts.contains(where: { $0.key.isEmpty }) {
            return "Every item needs a keyboard shortcut."
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Group Name")
                    .font(.headline)
                TextField("Group name", text: $groupName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Group Name")
            }

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Text("Name")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if groupType == .shortcuts {
                        Text("Shortcut")
                            .frame(width: 150, alignment: .leading)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(.quaternary.opacity(0.45))

                Divider()

                if drafts.isEmpty {
                    EmptyStateView(
                        title: "No shortcuts",
                        detail: "Add an item to this group."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(drafts) { draft in
                                let draftID = draft.id
                                ShortcutEditorRow(
                                    draft: draftBinding(for: draft),
                                    showsShortcut: groupType == .shortcuts,
                                    isSelected: selectedID == draftID,
                                    select: { selectedID = draftID },
                                    delete: { removeDraft(id: draftID) }
                                )
                                if draftID != drafts.last?.id {
                                    Divider().padding(.leading, 10)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 0.5)
            }

            VStack(spacing: 7) {
                HStack {
                    Button {
                        let draft = ShortcutDraft(sortOrder: drafts.count)
                        drafts.append(draft)
                        selectedID = draft.id
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityLabel("Add Item")

                    Button {
                        removeSelected()
                    } label: {
                        Label("Remove", systemImage: "minus")
                    }
                    .disabled(selectedID == nil)
                    .accessibilityLabel("Remove selected shortcut")

                    Spacer()

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }

                    Button("Cancel", action: cancel)
                        .keyboardShortcut(.cancelAction)
                    Button("Save", action: save)
                        .keyboardShortcut(.defaultAction)
                        .disabled(validationMessage != nil)
                }

                ZStack {
                    if saveToastID != nil {
                        Text("Saved")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(Color.green.opacity(0.18), in: Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            .accessibilityLabel("Saved")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .center)
                .animation(.easeInOut(duration: 0.18), value: saveToastID)
            }
        }
        .padding(20)
        .frame(minWidth: 620, idealWidth: 660, minHeight: 400, idealHeight: 450)
        .onDeleteCommand(perform: removeSelected)
        .onExitCommand(perform: cancel)
        .alert("Couldn’t Save Changes", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private func removeSelected() {
        guard let selectedID else { return }
        removeDraft(id: selectedID)
    }

    private func removeDraft(id: UUID) {
        if selectedID == id {
            selectedID = nil
        }
        drafts = drafts.filter { $0.id != id }
        normalizeDraftOrder()
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
            }
        )
    }

    private func normalizeDraftOrder() {
        for index in drafts.indices {
            drafts[index].sortOrder = index
        }
    }

    private func save() {
        guard validationMessage == nil else { return }
        NSApp.keyWindow?.makeFirstResponder(nil)
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let allGroups = try modelContext.fetch(FetchDescriptor<ShortcutGroup>())
            guard let group = allGroups.first(where: { $0.id == groupID }) else {
                errorMessage = "This group no longer exists."
                return
            }
            if allGroups.contains(where: {
                $0.id != groupID && $0.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) {
                errorMessage = "A group with this name already exists."
                return
            }

            group.name = trimmedName
            let existingByID = Dictionary(uniqueKeysWithValues: group.shortcuts.map { ($0.id, $0) })
            let keptIDs = Set(drafts.map(\.id))

            let itemsToDelete = group.shortcuts.filter { !keptIDs.contains($0.id) }
            for item in itemsToDelete {
                modelContext.delete(item)
            }

            for (index, draft) in drafts.enumerated() {
                if let item = existingByID[draft.id] {
                    item.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    item.key = draft.key
                    item.modifiersRawValue = draft.modifiers.rawValue
                    item.sortOrder = index
                } else {
                    let item = ShortcutItem(
                        id: draft.id,
                        name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        key: draft.key,
                        modifiersRawValue: draft.modifiers.rawValue,
                        sortOrder: index
                    )
                    modelContext.insert(item)
                    group.shortcuts.append(item)
                }
            }

            try modelContext.save()
            showSavedToast()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func showSavedToast() {
        let toastID = UUID()
        saveToastID = toastID

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard saveToastID == toastID else { return }
            saveToastID = nil
        }
    }
}

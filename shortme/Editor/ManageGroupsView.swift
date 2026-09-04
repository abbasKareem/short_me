import SwiftData
import SwiftUI

struct ManageGroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ShortcutGroup.sortOrder), SortDescriptor(\ShortcutGroup.createdAt)])
    private var groups: [ShortcutGroup]

    let editGroup: (UUID) -> Void
    @State private var nameDrafts: [UUID: String] = [:]
    @State private var pendingDeletionID: UUID?
    @State private var errorMessage: String?
    @FocusState private var focusedGroupID: UUID?

    private var pendingDeletion: ShortcutGroup? {
        guard let pendingDeletionID else { return nil }
        return groups.first { $0.id == pendingDeletionID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manage Groups")
                .font(.title2.weight(.semibold))

            GroupBox {
                if groups.isEmpty {
                    EmptyStateView(
                        title: "No groups",
                        detail: "Add a group to get started."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                                HStack(spacing: 8) {
                                    TextField(group.name, text: nameBinding(for: group))
                                        .textFieldStyle(.plain)
                                        .focused($focusedGroupID, equals: group.id)
                                        .onSubmit { commitName(for: group) }

                                    Picker("Type", selection: typeBinding(for: group)) {
                                        ForEach(ShortcutGroupType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 105)
                                    .accessibilityLabel("Type for \(group.name)")

                                    Button {
                                        move(group, by: -1)
                                    } label: {
                                        Image(systemName: "chevron.up")
                                    }
                                    .disabled(index == 0)
                                    .help("Move Up")

                                    Button {
                                        move(group, by: 1)
                                    } label: {
                                        Image(systemName: "chevron.down")
                                    }
                                    .disabled(index == groups.count - 1)
                                    .help("Move Down")

                                    Button("Edit") {
                                        commitName(for: group)
                                        editGroup(group.id)
                                    }

                                    Button(role: .destructive) {
                                        requestDelete(group)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .accessibilityLabel("Delete \(group.name)")
                                }
                                .buttonStyle(.borderless)
                                .padding(.horizontal, 8)
                                .frame(height: 44)

                                if index < groups.count - 1 { Divider() }
                            }
                        }
                    }
                }
            }

            HStack {
                Button {
                    addGroup()
                } label: {
                    Label("Add Group", systemImage: "plus")
                }
                .accessibilityLabel("Add Group")
                Spacer()
            }
        }
        .padding(20)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 330, idealHeight: 400)
        .onAppear { synchronizeDraftNames() }
        .onChange(of: groups.map(\.id)) { _, _ in synchronizeDraftNames() }
        .onChange(of: focusedGroupID) { oldValue, _ in
            guard let oldValue, let group = groups.first(where: { $0.id == oldValue }) else { return }
            commitName(for: group)
        }
        .alert(
            pendingDeletion.map { "Delete “" + $0.name + "”?" } ?? "Delete Group?",
            isPresented: Binding(
                get: { pendingDeletionID != nil },
                set: { if !$0 { pendingDeletionID = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { pendingDeletionID = nil }
            Button("Delete", role: .destructive) { confirmDelete() }
        } message: {
            Text("This will also delete all shortcuts in this group.")
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

    private func nameBinding(for group: ShortcutGroup) -> Binding<String> {
        Binding(
            get: { nameDrafts[group.id] ?? group.name },
            set: { nameDrafts[group.id] = $0 }
        )
    }

    private func typeBinding(for group: ShortcutGroup) -> Binding<ShortcutGroupType> {
        Binding(
            get: { group.groupType },
            set: { newType in
                group.groupType = newType
                saveContext()
            }
        )
    }

    private func synchronizeDraftNames() {
        for group in groups where nameDrafts[group.id] == nil {
            nameDrafts[group.id] = group.name
        }
        let currentIDs = Set(groups.map(\.id))
        nameDrafts = nameDrafts.filter { currentIDs.contains($0.key) }
    }

    private func commitName(for group: ShortcutGroup) {
        let proposed = (nameDrafts[group.id] ?? group.name).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !proposed.isEmpty else {
            nameDrafts[group.id] = group.name
            errorMessage = "Group name is required."
            return
        }
        guard !groups.contains(where: {
            $0.id != group.id && $0.name.compare(proposed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) else {
            nameDrafts[group.id] = group.name
            errorMessage = "A group with this name already exists."
            return
        }
        group.name = proposed
        nameDrafts[group.id] = proposed
        saveContext()
    }

    private func addGroup() {
        let existingNames = Set(groups.map { $0.name.lowercased() })
        var candidate = "New Group"
        var suffix = 2
        while existingNames.contains(candidate.lowercased()) {
            candidate = "New Group \(suffix)"
            suffix += 1
        }
        let group = ShortcutGroup(name: candidate, sortOrder: groups.count)
        modelContext.insert(group)
        saveContext()
        nameDrafts[group.id] = candidate
        focusedGroupID = group.id
    }

    private func requestDelete(_ group: ShortcutGroup) {
        if group.shortcuts.isEmpty {
            modelContext.delete(group)
            saveContext()
        } else {
            pendingDeletionID = group.id
        }
    }

    private func confirmDelete() {
        guard let group = pendingDeletion else { return }
        modelContext.delete(group)
        pendingDeletionID = nil
        saveContext()
    }

    private func move(_ group: ShortcutGroup, by offset: Int) {
        guard let sourceIndex = groups.firstIndex(where: { $0.id == group.id }) else { return }
        let destinationIndex = sourceIndex + offset
        guard groups.indices.contains(destinationIndex) else { return }
        var ordered = groups
        ordered.swapAt(sourceIndex, destinationIndex)
        for (index, item) in ordered.enumerated() { item.sortOrder = index }
        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            synchronizeDraftNames()
        }
    }
}

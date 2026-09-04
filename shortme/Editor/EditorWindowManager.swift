import AppKit
import SwiftData

@MainActor
final class EditorWindowManager {
    private let modelContainer: ModelContainer
    private var manageGroupsController: ManageGroupsWindowController?
    private var editorControllers: [UUID: GroupEditorWindowController] = [:]

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func showManageGroups() {
        NSApp.activate()
        if let manageGroupsController {
            manageGroupsController.showWindow(nil)
            manageGroupsController.window?.makeKeyAndOrderFront(nil)
            return
        }

        let controller = ManageGroupsWindowController(
            modelContainer: modelContainer,
            editGroup: { [weak self] groupID in self?.showEditor(for: groupID) }
        )
        controller.onClose = { [weak self] in self?.manageGroupsController = nil }
        manageGroupsController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    func showEditor(for groupID: UUID) {
        NSApp.activate()
        if let existing = editorControllers[groupID] {
            existing.showWindow(nil)
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }

        let context = modelContainer.mainContext
        guard let group = (try? context.fetch(FetchDescriptor<ShortcutGroup>()))?.first(where: { $0.id == groupID }) else {
            NSSound.beep()
            return
        }

        let controller = GroupEditorWindowController(group: group, modelContext: context)
        controller.onClose = { [weak self] closedID in self?.editorControllers[closedID] = nil }
        editorControllers[groupID] = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }
}

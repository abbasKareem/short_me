import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let persistence = PersistenceController()
    private let appState = AppState()
    private var floatingButtonController: FloatingButtonWindowController?
    private var shortcutPanelController: ShortcutPanelController?
    private var editorWindowManager: EditorWindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            try SeedDataService.seedIfNeeded(in: persistence.container.mainContext)
        } catch {
            presentStartupError(error)
        }

        if let startupError = persistence.startupError {
            presentStartupError(startupError)
        }

        let editorManager = EditorWindowManager(modelContainer: persistence.container)
        let shortcutController = ShortcutPanelController(
            modelContainer: persistence.container,
            appState: appState,
            editGroup: { [weak editorManager] groupID in
                editorManager?.showEditor(for: groupID)
            },
            manageGroups: { [weak editorManager] in
                editorManager?.showManageGroups()
            }
        )
        let floatingController = FloatingButtonWindowController(
            shortcutPanelController: shortcutController,
            manageGroups: { [weak editorManager] in
                editorManager?.showManageGroups()
            }
        )

        editorWindowManager = editorManager
        shortcutPanelController = shortcutController
        floatingButtonController = floatingController
        shortcutController.buttonFrameProvider = { [weak floatingController] in
            floatingController?.buttonFrame
        }
        floatingController.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func presentStartupError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Shortme could not open its saved data."
        alert.informativeText = "The app will continue for this session. \(error.localizedDescription)"
        alert.runModal()
    }
}

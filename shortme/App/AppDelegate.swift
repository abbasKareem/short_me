import AppKit
import Carbon
import SwiftData

private let focusPanelHotKeySignature = OSType(0x53484D45) // "SHME"
private let focusPanelHotKeyID: UInt32 = 1

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let persistence = PersistenceController()
    private let appState = AppState()
    private var floatingButtonController: FloatingButtonWindowController?
    private var shortcutPanelController: ShortcutPanelController?
    private var editorWindowManager: EditorWindowManager?
    private var focusPanelHotKey: EventHotKeyRef?
    private var focusPanelEventHandler: EventHandlerRef?

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
        registerFocusPanelHotKey()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        unregisterFocusPanelHotKey()
    }

    fileprivate func toggleShortcutPanel() {
        guard let shortcutPanelController else { return }
        if shortcutPanelController.isVisible, shortcutPanelController.isFocused {
            shortcutPanelController.close()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            shortcutPanelController.focusOrShow()
        }
    }

    private func registerFocusPanelHotKey() {
        guard focusPanelHotKey == nil, focusPanelEventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return OSStatus(eventNotHandledErr)
                }

                var pressedHotKey = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &pressedHotKey
                )
                guard
                    parameterStatus == noErr,
                    pressedHotKey.signature == focusPanelHotKeySignature,
                    pressedHotKey.id == focusPanelHotKeyID
                else {
                    return OSStatus(eventNotHandledErr)
                }

                let appDelegate = Unmanaged<AppDelegate>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                MainActor.assumeIsolated {
                    appDelegate.toggleShortcutPanel()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &focusPanelEventHandler
        )
        guard handlerStatus == noErr else {
            NSLog("Unable to install the Shortme hot-key handler: %d", handlerStatus)
            return
        }

        let hotKey = EventHotKeyID(
            signature: focusPanelHotKeySignature,
            id: focusPanelHotKeyID
        )
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_X),
            UInt32(cmdKey | shiftKey),
            hotKey,
            GetApplicationEventTarget(),
            0,
            &focusPanelHotKey
        )
        guard registrationStatus == noErr else {
            NSLog("Unable to register Command-Shift-X: %d", registrationStatus)
            if let focusPanelEventHandler {
                RemoveEventHandler(focusPanelEventHandler)
                self.focusPanelEventHandler = nil
            }
            return
        }
    }

    private func unregisterFocusPanelHotKey() {
        if let focusPanelHotKey {
            UnregisterEventHotKey(focusPanelHotKey)
            self.focusPanelHotKey = nil
        }
        if let focusPanelEventHandler {
            RemoveEventHandler(focusPanelEventHandler)
            self.focusPanelEventHandler = nil
        }
    }

    private func presentStartupError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Shortme could not open its saved data."
        alert.informativeText = "The app will continue for this session. \(error.localizedDescription)"
        alert.runModal()
    }
}

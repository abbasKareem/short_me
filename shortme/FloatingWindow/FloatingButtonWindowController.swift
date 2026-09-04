import AppKit

@MainActor
final class FloatingButtonWindowController: NSWindowController {
    private static let buttonSize = CGSize(width: 40, height: 40)

    private let shortcutPanelController: ShortcutPanelController
    private let manageGroups: () -> Void
    private let positionStore = FloatingButtonPositionStore()
    private let visualState = FloatingButtonVisualState()
    private var screenObserver: NSObjectProtocol?

    var buttonFrame: CGRect? { window?.frame }

    init(shortcutPanelController: ShortcutPanelController, manageGroups: @escaping () -> Void) {
        self.shortcutPanelController = shortcutPanelController
        self.manageGroups = manageGroups

        let frame = CGRect(origin: .zero, size: Self.buttonSize)
        let panel = FloatingButtonPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        super.init(window: panel)
        configureContent()
        observeScreens()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    func show() {
        guard let window else { return }
        if let restored = positionStore.restoredFrame(buttonSize: Self.buttonSize) {
            window.setFrame(restored, display: false)
        } else {
            moveToDefaultPosition()
        }
        window.orderFrontRegardless()
    }

    private func configureContent() {
        let hostingView = FloatingButtonHostingView(state: visualState)
        hostingView.onClick = { [weak self] in
            guard let self else { return }
            shortcutPanelController.toggle()
            visualState.isMenuOpen = shortcutPanelController.isVisible
        }
        hostingView.onDragBegan = { [weak self] in
            self?.shortcutPanelController.close()
        }
        hostingView.onDragEnded = { [weak self] in
            self?.savePosition()
        }
        hostingView.contextMenuProvider = { [weak self] in
            self?.makeContextMenu() ?? NSMenu()
        }
        window?.contentView = hostingView

        shortcutPanelController.onVisibilityChange = { [weak self] isVisible in
            self?.visualState.isMenuOpen = isVisible
        }
    }

    private func savePosition() {
        guard let frame = window?.frame else { return }
        positionStore.save(frame: frame, on: WindowPositionService.screen(for: frame))
    }

    private func moveToDefaultPosition() {
        guard let window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let origin = WindowPositionService.defaultButtonOrigin(on: screen, buttonSize: Self.buttonSize)
        window.setFrame(CGRect(origin: origin, size: Self.buttonSize), display: true)
        positionStore.save(frame: window.frame, on: screen)
        shortcutPanelController.close()
    }

    private func observeScreens() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.ensureVisibleOnAConnectedScreen()
            }
        }
    }

    private func ensureVisibleOnAConnectedScreen() {
        guard let window else { return }
        guard let screen = NSScreen.containing(window.frame) else {
            moveToDefaultPosition()
            return
        }
        let clamped = WindowPositionService.clampedButtonFrame(window.frame, on: screen)
        window.setFrame(clamped, display: true)
        positionStore.save(frame: clamped, on: screen)
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Manage Groups", action: #selector(showManageGroups), keyEquivalent: "")
        menu.addItem(withTitle: "Reset Floating Button Position", action: #selector(resetPosition), keyEquivalent: "")
        menu.addItem(withTitle: "About Shortme", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Shortme", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func showManageGroups() {
        manageGroups()
    }

    @objc private func resetPosition() {
        positionStore.reset()
        moveToDefaultPosition()
    }

    @objc private func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

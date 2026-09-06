import AppKit
import QuartzCore
import SwiftData
import SwiftUI

@MainActor
final class ShortcutPanelController: NSWindowController {
    private let appState: AppState
    private let panelWidth: CGFloat = 360
    private var preferredHeight: CGFloat = 306
    private let editGroupAction: (UUID) -> Void
    private let manageGroupsAction: () -> Void

    var buttonFrameProvider: (() -> CGRect?)?
    var onVisibilityChange: ((Bool) -> Void)?
    var isVisible: Bool { window?.isVisible == true }
    var isFocused: Bool { window?.isKeyWindow == true }

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        editGroup: @escaping (UUID) -> Void,
        manageGroups: @escaping () -> Void
    ) {
        self.appState = appState
        editGroupAction = editGroup
        manageGroupsAction = manageGroups

        let panel = ShortcutPanel(
            contentRect: CGRect(x: 0, y: 0, width: panelWidth, height: preferredHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        super.init(window: panel)
        let rootView = ShortcutPanelRootView(
            appState: appState,
            close: { [weak self] in self?.close() },
            editGroup: { [weak self] groupID in
                self?.close()
                self?.editGroupAction(groupID)
            },
            manageGroups: { [weak self] in
                self?.close()
                self?.manageGroupsAction()
            },
            preferredHeightChanged: { [weak self] height in
                self?.resize(to: height)
            }
        )
        let hostingView = NSHostingView(rootView: rootView.modelContainer(modelContainer))
        panel.contentView = hostingView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggle() {
        isVisible ? close() : show()
    }

    func focusOrShow() {
        if isVisible {
            window?.makeKeyAndOrderFront(nil)
        } else {
            show()
        }
    }

    func show() {
        guard let window, let buttonFrame = buttonFrameProvider?() else { return }
        appState.resetBrowser()
        appState.isShortcutPanelVisible = true
        position(window: window, nextTo: buttonFrame)
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        onVisibilityChange?(true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1
        }
    }

    override func close() {
        guard isVisible else {
            appState.resetBrowser()
            appState.isShortcutPanelVisible = false
            return
        }
        window?.orderOut(nil)
        appState.resetBrowser()
        appState.isShortcutPanelVisible = false
        onVisibilityChange?(false)
    }

    private func resize(to height: CGFloat) {
        let clampedHeight = min(max(height, 180), 500)
        guard preferredHeight != clampedHeight else { return }
        preferredHeight = clampedHeight
        guard let window, isVisible, let buttonFrame = buttonFrameProvider?() else { return }
        position(window: window, nextTo: buttonFrame)
    }

    private func position(window: NSWindow, nextTo buttonFrame: CGRect) {
        let screen = WindowPositionService.screen(for: buttonFrame)
        let height = min(preferredHeight, screen.visibleFrame.height - 20)
        let size = CGSize(width: panelWidth, height: height)
        let origin = PanelPlacement.origin(
            buttonFrame: buttonFrame,
            panelSize: size,
            visibleFrame: screen.visibleFrame
        )
        window.setFrame(CGRect(origin: origin, size: size), display: true, animate: false)
    }
}

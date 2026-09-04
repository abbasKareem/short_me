import AppKit
import SwiftUI

@MainActor
final class FloatingButtonHostingView: NSHostingView<FloatingButtonView>, NSMenuDelegate {
    var onClick: (() -> Void)?
    var onDragEnded: (() -> Void)?
    var onDragBegan: (() -> Void)?
    var contextMenuProvider: (() -> NSMenu)?

    private let visualState: FloatingButtonVisualState
    private var trackingAreaReference: NSTrackingArea?
    private var mouseDownLocation = CGPoint.zero
    private var windowOriginAtMouseDown = CGPoint.zero
    private var didDrag = false

    init(state: FloatingButtonVisualState) {
        visualState = state
        super.init(rootView: FloatingButtonView(state: state))
    }

    @available(*, unavailable)
    required init(rootView: FloatingButtonView) {
        fatalError("Use init(state:)")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        if let trackingAreaReference {
            removeTrackingArea(trackingAreaReference)
        }
        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self
        )
        addTrackingArea(tracking)
        trackingAreaReference = tracking
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        visualState.isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        visualState.isHovered = false
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        mouseDownLocation = NSEvent.mouseLocation
        windowOriginAtMouseDown = window.frame.origin
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let location = NSEvent.mouseLocation
        let delta = CGPoint(
            x: location.x - mouseDownLocation.x,
            y: location.y - mouseDownLocation.y
        )

        if !didDrag, hypot(delta.x, delta.y) >= 4 {
            didDrag = true
            visualState.isDragging = true
            onDragBegan?()
        }
        guard didDrag else { return }

        let proposed = CGRect(
            origin: CGPoint(
                x: windowOriginAtMouseDown.x + delta.x,
                y: windowOriginAtMouseDown.y + delta.y
            ),
            size: window.frame.size
        )
        let screen = WindowPositionService.screen(for: proposed)
        window.setFrameOrigin(WindowPositionService.clampedButtonFrame(proposed, on: screen).origin)
    }

    override func mouseUp(with event: NSEvent) {
        if didDrag {
            visualState.isDragging = false
            onDragEnded?()
        } else {
            onClick?()
        }
        didDrag = false
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = contextMenuProvider?() else { return }
        visualState.isContextMenuOpen = true
        menu.delegate = self
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    func menuDidClose(_ menu: NSMenu) {
        visualState.isContextMenuOpen = false
    }
}

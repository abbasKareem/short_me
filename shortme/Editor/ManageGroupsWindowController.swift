import AppKit
import SwiftData
import SwiftUI

@MainActor
final class ManageGroupsWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    init(modelContainer: ModelContainer, editGroup: @escaping (UUID) -> Void) {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Manage Groups"
        window.minSize = CGSize(width: 460, height: 330)
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
        window.contentView = NSHostingView(
            rootView: ManageGroupsView(editGroup: editGroup).modelContainer(modelContainer)
        )
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}

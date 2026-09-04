import AppKit
import SwiftData
import SwiftUI

@MainActor
final class GroupEditorWindowController: NSWindowController, NSWindowDelegate {
    private let groupID: UUID
    var onClose: ((UUID) -> Void)?

    init(group: ShortcutGroup, modelContext: ModelContext) {
        groupID = group.id
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 660, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Edit Group — \(group.name)"
        window.minSize = CGSize(width: 620, height: 400)
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
        window.contentView = NSHostingView(rootView: GroupEditorView(
            group: group,
            modelContext: modelContext,
            cancel: { [weak self] in self?.close() }
        ))
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onClose?(groupID)
    }
}

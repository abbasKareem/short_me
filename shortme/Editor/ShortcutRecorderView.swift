import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var key: String
    @Binding var modifiers: ShortcutModifiers

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onChange = { newKey, newModifiers in
            key = newKey
            modifiers = newModifiers
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.key = key
        nsView.modifiers = modifiers
        nsView.refresh()
    }
}

@MainActor
final class ShortcutRecorderNSView: NSView {
    var key = ""
    var modifiers: ShortcutModifiers = []
    var onChange: ((String, ShortcutModifiers) -> Void)?

    private let label = NSTextField(labelWithString: "")
    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        label.alignment = .center
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 132, height: 28) }

    override func updateLayer() {
        layer?.cornerRadius = 6
        layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.09).cgColor
        layer?.borderWidth = isRecording ? 1.5 : 0.5
        layer?.borderColor = (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        refresh()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            stopRecording()
            return
        }
        if event.keyCode == 51 || event.keyCode == 117 {
            onChange?("", [])
            stopRecording()
            return
        }

        let newModifiers = ShortcutModifiers(eventFlags: event.modifierFlags)
        guard let newKey = KeyboardShortcutFormatter.normalizedKey(from: event), !newKey.isEmpty else {
            NSSound.beep()
            return
        }
        onChange?(newKey, newModifiers)
        stopRecording()
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        refresh()
        return super.resignFirstResponder()
    }

    func refresh() {
        if isRecording {
            label.stringValue = "Type…"
            setAccessibilityLabel("Keyboard shortcut, recording")
        } else if key.isEmpty {
            label.stringValue = "Record"
            setAccessibilityLabel("Keyboard shortcut, not set")
        } else {
            label.stringValue = KeyboardShortcutFormatter.displayString(key: key, modifiers: modifiers)
            let spoken = KeyboardShortcutFormatter.accessibilityString(key: key, modifiers: modifiers)
            setAccessibilityLabel("Keyboard shortcut, \(spoken)")
        }
        needsDisplay = true
    }

    private func stopRecording() {
        isRecording = false
        window?.makeFirstResponder(nil)
        refresh()
    }
}

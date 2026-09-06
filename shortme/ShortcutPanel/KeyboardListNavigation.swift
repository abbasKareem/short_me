import AppKit
import SwiftUI

enum KeyboardListNavigationDirection: Equatable {
    case up
    case down
}

private struct KeyboardListNavigation: NSViewRepresentable {
    let onMove: (KeyboardListNavigationDirection) -> Void
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMove: onMove, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> NSView {
        let view = KeyboardObserverView()
        context.coordinator.view = view
        context.coordinator.startObserving()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onMove = onMove
        context.coordinator.onSubmit = onSubmit
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopObserving()
    }

    final class Coordinator {
        weak var view: NSView?
        var onMove: (KeyboardListNavigationDirection) -> Void
        var onSubmit: () -> Void

        private var eventMonitor: Any?

        init(
            onMove: @escaping (KeyboardListNavigationDirection) -> Void,
            onSubmit: @escaping () -> Void
        ) {
            self.onMove = onMove
            self.onSubmit = onSubmit
        }

        deinit {
            stopObserving()
        }

        func startObserving() {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard
                    let self,
                    let view = self.view,
                    event.window === view.window
                else {
                    return event
                }

                // Let the shortcut recorder capture arrow and Return keys when it is active.
                guard !(view.window?.firstResponder is ShortcutRecorderNSView) else {
                    return event
                }

                let navigationModifiers = event.modifierFlags.intersection([
                    .command,
                    .control,
                    .option,
                    .shift,
                ])
                guard navigationModifiers.isEmpty else { return event }

                switch event.keyCode {
                case 126:
                    self.onMove(.up)
                    return nil
                case 125:
                    self.onMove(.down)
                    return nil
                case 36, 76:
                    self.onSubmit()
                    return nil
                default:
                    return event
                }
            }
        }

        func stopObserving() {
            guard let eventMonitor else { return }
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}

private final class KeyboardObserverView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

extension View {
    func keyboardListNavigation(
        onMove: @escaping (KeyboardListNavigationDirection) -> Void,
        onSubmit: @escaping () -> Void
    ) -> some View {
        background {
            KeyboardListNavigation(onMove: onMove, onSubmit: onSubmit)
                .frame(width: 0, height: 0)
        }
    }
}

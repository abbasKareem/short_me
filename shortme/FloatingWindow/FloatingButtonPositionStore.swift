import AppKit

@MainActor
final class FloatingButtonPositionStore {
    private enum Key {
        static let x = "floatingButtonPosition.x"
        static let y = "floatingButtonPosition.y"
        static let screen = "floatingButtonPosition.screen"
        static let saved = "floatingButtonPosition.saved"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(frame: CGRect, on screen: NSScreen) {
        defaults.set(Double(frame.minX), forKey: Key.x)
        defaults.set(Double(frame.minY), forKey: Key.y)
        defaults.set(screen.persistentIdentifier, forKey: Key.screen)
        defaults.set(true, forKey: Key.saved)
    }

    func restoredFrame(buttonSize: CGSize) -> CGRect? {
        guard defaults.bool(forKey: Key.saved),
              let screenID = defaults.string(forKey: Key.screen),
              let screen = NSScreen.screens.first(where: { $0.persistentIdentifier == screenID })
        else {
            return nil
        }

        let frame = CGRect(
            x: defaults.double(forKey: Key.x),
            y: defaults.double(forKey: Key.y),
            width: buttonSize.width,
            height: buttonSize.height
        )
        guard screen.visibleFrame.intersects(frame) else { return nil }
        return WindowPositionService.clampedButtonFrame(frame, on: screen)
    }

    func reset() {
        defaults.removeObject(forKey: Key.x)
        defaults.removeObject(forKey: Key.y)
        defaults.removeObject(forKey: Key.screen)
        defaults.removeObject(forKey: Key.saved)
    }
}

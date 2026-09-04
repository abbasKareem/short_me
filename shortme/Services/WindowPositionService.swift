import AppKit

@MainActor
enum WindowPositionService {
    static func screen(for frame: CGRect) -> NSScreen {
        NSScreen.containing(frame) ?? NSScreen.main ?? NSScreen.screens[0]
    }

    static func defaultButtonOrigin(on screen: NSScreen, buttonSize: CGSize) -> CGPoint {
        let visible = screen.visibleFrame
        return CGPoint(
            x: visible.maxX - buttonSize.width - 14,
            y: visible.midY - buttonSize.height / 2
        )
    }

    static func clampedButtonFrame(_ frame: CGRect, on screen: NSScreen) -> CGRect {
        PanelPlacement.clamp(frame: frame, to: screen.visibleFrame)
    }
}

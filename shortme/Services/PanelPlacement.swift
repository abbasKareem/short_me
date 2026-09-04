import CoreGraphics

enum PanelPlacement {
    static func origin(
        buttonFrame: CGRect,
        panelSize: CGSize,
        visibleFrame: CGRect,
        gap: CGFloat = 10
    ) -> CGPoint {
        let rightOrigin = buttonFrame.maxX + gap
        let leftOrigin = buttonFrame.minX - gap - panelSize.width
        let availableRight = visibleFrame.maxX - buttonFrame.maxX
        let availableLeft = buttonFrame.minX - visibleFrame.minX

        let x: CGFloat
        if rightOrigin + panelSize.width <= visibleFrame.maxX || availableRight >= availableLeft {
            x = rightOrigin
        } else {
            x = leftOrigin
        }

        let centeredY = buttonFrame.midY - panelSize.height / 2
        return CGPoint(
            x: min(max(x, visibleFrame.minX), visibleFrame.maxX - panelSize.width),
            y: min(max(centeredY, visibleFrame.minY), visibleFrame.maxY - panelSize.height)
        )
    }

    static func clamp(frame: CGRect, to visibleFrame: CGRect, margin: CGFloat = 4) -> CGRect {
        let safeFrame = visibleFrame.insetBy(dx: margin, dy: margin)
        let x = min(max(frame.minX, safeFrame.minX), safeFrame.maxX - frame.width)
        let y = min(max(frame.minY, safeFrame.minY), safeFrame.maxY - frame.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: frame.size)
    }
}

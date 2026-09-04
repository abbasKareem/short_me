import AppKit

extension NSScreen {
    var persistentIdentifier: String {
        if let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return number.stringValue
        }
        return localizedName
    }

    static func containing(_ rect: CGRect) -> NSScreen? {
        screens.max { first, second in
            first.frame.intersection(rect).area < second.frame.intersection(rect).area
        }.flatMap { $0.frame.intersects(rect) ? $0 : nil }
    }
}

private extension CGRect {
    var area: CGFloat { max(width, 0) * max(height, 0) }
}

import AppKit
import Foundation

extension NSColor {
    static let perchMutedWhite = NSColor(calibratedRed: 221.0 / 255.0, green: 227.0 / 255.0, blue: 231.0 / 255.0, alpha: 1)
}

enum MenuIconRenderer {
    static func dateIcon(day: Int) -> NSImage {
        let size = NSSize(width: 26, height: 22)
        let image = NSImage(size: size)

        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        NSColor(calibratedRed: 0.27, green: 0.49, blue: 0.68, alpha: 1).setFill()
        NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4).fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.perchMutedWhite,
            .paragraphStyle: paragraphStyle
        ]

        String(day).draw(
            in: NSRect(x: 0, y: 3, width: size.width, height: 16),
            withAttributes: attributes
        )

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    static func colorBar(color: NSColor, size: NSSize = NSSize(width: 5, height: 16)) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()
        color.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 2, yRadius: 2).fill()
        image.unlockFocus()

        image.isTemplate = false
        return image
    }

    static func zoomIcon(size: NSSize = NSSize(width: 16, height: 16)) -> NSImage {
        let image = NSImage(size: size)
        let rect = NSRect(origin: .zero, size: size)

        image.lockFocus()

        NSColor(calibratedRed: 0.05, green: 0.45, blue: 0.93, alpha: 1).setFill()
        NSBezierPath(
            roundedRect: rect.insetBy(dx: 1, dy: 1),
            xRadius: 3,
            yRadius: 3
        ).fill()

        NSColor.white.setFill()
        NSBezierPath(
            roundedRect: NSRect(x: 4, y: 5.5, width: 6.5, height: 5),
            xRadius: 1,
            yRadius: 1
        ).fill()

        let lens = NSBezierPath()
        lens.move(to: NSPoint(x: 10.5, y: 7))
        lens.line(to: NSPoint(x: 13, y: 5.75))
        lens.line(to: NSPoint(x: 13, y: 10.25))
        lens.line(to: NSPoint(x: 10.5, y: 9))
        lens.close()
        lens.fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

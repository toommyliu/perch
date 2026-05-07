import AppKit
import Foundation

extension NSColor {
    static let perchMutedWhite = NSColor(calibratedRed: 221.0 / 255.0, green: 227.0 / 255.0, blue: 231.0 / 255.0, alpha: 1)
}

enum MenuIconRenderer {
    static func dateIcon(day: Int) -> NSImage {
        let size = NSSize(width: 25, height: 20)
        let image = NSImage(size: size)

        image.lockFocus()

        let primaryColor = NSColor.black
        primaryColor.setStroke()
        primaryColor.setFill()

        let calendarRect = NSRect(x: 3.25, y: 2.25, width: 18.5, height: 15.0)
        let calendarPath = NSBezierPath(roundedRect: calendarRect, xRadius: 3.25, yRadius: 3.25)
        calendarPath.lineWidth = 1.6
        calendarPath.stroke()

        let headerPath = NSBezierPath()
        headerPath.lineWidth = 1.35
        headerPath.lineCapStyle = .round
        headerPath.move(to: NSPoint(x: 5.6, y: 13.2))
        headerPath.line(to: NSPoint(x: 19.4, y: 13.2))
        headerPath.stroke()

        NSBezierPath(ovalIn: NSRect(x: 7.2, y: 15.45, width: 2.0, height: 2.0)).fill()
        NSBezierPath(ovalIn: NSRect(x: 15.8, y: 15.45, width: 2.0, height: 2.0)).fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: day < 10 ? 10.5 : 9.8, weight: .semibold),
            .foregroundColor: primaryColor,
            .paragraphStyle: paragraphStyle
        ]

        String(day).draw(
            in: NSRect(x: 3.5, y: 4.0, width: 18.0, height: 10.5),
            withAttributes: attributes
        )

        image.unlockFocus()
        image.isTemplate = true
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

import AppKit
import CoreText
import Foundation

extension NSColor {
    static let perchMutedWhite = NSColor(calibratedRed: 221.0 / 255.0, green: 227.0 / 255.0, blue: 231.0 / 255.0, alpha: 1)
}

enum MenuIconRenderer {
    static func dateIcon(day: Int) -> NSImage {
        let size = NSSize(width: 22, height: 19)
        let image = NSImage(size: size)

        image.lockFocus()

        let primaryColor = NSColor.black
        primaryColor.setStroke()
        primaryColor.setFill()

        let calendarRect = NSRect(x: 3.5, y: 1.5, width: 15.0, height: 14.75)
        let calendarPath = NSBezierPath(roundedRect: calendarRect, xRadius: 3.0, yRadius: 3.0)
        calendarPath.lineWidth = 1.35

        NSGraphicsContext.saveGraphicsState()
        calendarPath.addClip()
        NSBezierPath(rect: NSRect(x: calendarRect.minX, y: 12.9, width: calendarRect.width, height: calendarRect.maxY - 12.9)).fill()
        NSGraphicsContext.restoreGraphicsState()

        calendarPath.stroke()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: day < 10 ? 9.6 : 8.1, weight: .bold),
            .foregroundColor: primaryColor
        ]
        let dayString = NSAttributedString(string: String(day), attributes: attributes)
        let textRect = NSRect(x: 3.5, y: 2.3, width: 15.0, height: 10.6)
        drawCentered(dayString, in: textRect, offset: dayTextOffset(for: day))

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private static func dayTextOffset(for day: Int) -> NSSize {
        let dayText = String(day)

        if dayText.contains("1") {
            return NSSize(width: day < 10 ? 0.05 : 0.0, height: day < 10 ? 0.3 : 0.0)
        }

        return day < 10 ? NSSize(width: 0.45, height: 0.3) : NSSize(width: 0.25, height: 0.0)
    }

    private static func drawCentered(_ attributedString: NSAttributedString, in rect: NSRect, offset: NSSize = .zero) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            attributedString.draw(in: rect)
            return
        }

        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

        guard bounds.width.isFinite,
              bounds.height.isFinite,
              bounds.width > 0,
              bounds.height > 0
        else {
            attributedString.draw(in: rect)
            return
        }

        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(
            x: rect.midX - bounds.midX + offset.width,
            y: rect.midY - bounds.midY + offset.height
        )
        CTLineDraw(line, context)
        context.restoreGState()
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

import AppKit
import CoreText
import Foundation

extension NSColor {
    static let perchMutedWhite = NSColor(calibratedRed: 221.0 / 255.0, green: 227.0 / 255.0, blue: 231.0 / 255.0, alpha: 1)
}

#if DEBUG
struct DateIconRenderOptions: Equatable {
    var fontWeight: NSFont.Weight
    var opticalYOffset: CGFloat

    static let defaultValue = DateIconRenderOptions(
        fontWeight: .semibold,
        opticalYOffset: 0
    )
}
#endif

enum MenuIconRenderer {
    private struct DateTextMetrics: Sendable {
        let fontSize: CGFloat
        let tracking: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat
    }

    static func dateIcon(day: Int) -> NSImage {
        dateIcon(day: day, fontWeight: .semibold, opticalYOffset: 0)
    }

    #if DEBUG
    static func dateIcon(day: Int, options: DateIconRenderOptions) -> NSImage {
        dateIcon(day: day, fontWeight: options.fontWeight, opticalYOffset: options.opticalYOffset)
    }
    #endif

    private static func dateIcon(day: Int, fontWeight: NSFont.Weight, opticalYOffset: CGFloat) -> NSImage {
        let size = NSSize(width: 22, height: 19)
        let image = NSImage(size: size, flipped: false) { _ in
            drawDateIcon(day: day, fontWeight: fontWeight, opticalYOffset: opticalYOffset)
            return true
        }

        image.isTemplate = true
        return image
    }

    private static func drawDateIcon(day: Int, fontWeight: NSFont.Weight, opticalYOffset: CGFloat) {
        let primaryColor = NSColor.black
        primaryColor.setStroke()
        primaryColor.setFill()

        let calendarRect = pixelSnapped(NSRect(x: 3.5, y: 1.5, width: 15.0, height: 14.75))
        let calendarPath = NSBezierPath(roundedRect: calendarRect, xRadius: 3.0, yRadius: 3.0)
        calendarPath.lineWidth = 1.35

        NSGraphicsContext.saveGraphicsState()
        calendarPath.addClip()
        let headerMinY = pixelSnapped(12.9)
        let headerRect = pixelSnapped(NSRect(
            x: calendarRect.minX,
            y: headerMinY,
            width: calendarRect.width,
            height: calendarRect.maxY - headerMinY
        ))
        NSBezierPath(rect: headerRect).fill()
        NSGraphicsContext.restoreGraphicsState()

        calendarPath.stroke()

        let textRect = pixelSnapped(NSRect(x: 3.5, y: 2.15, width: 15.0, height: 10.9))
        drawDateText(day: day, color: primaryColor, in: textRect, fontWeight: fontWeight, opticalYOffset: opticalYOffset)
    }

    private static func drawDateText(
        day: Int,
        color: NSColor,
        in rect: NSRect,
        fontWeight: NSFont.Weight,
        opticalYOffset: CGFloat
    ) {
        let metrics = opticalDateTextMetrics(for: day)
        let font = NSFont.systemFont(ofSize: metrics.fontSize, weight: fontWeight)
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        if metrics.tracking != 0 {
            attributes[.kern] = metrics.tracking
        }

        let dayString = NSAttributedString(string: String(day), attributes: attributes)
        drawInkCentered(
            dayString,
            in: rect,
            opticalXOffset: metrics.xOffset,
            opticalYOffset: metrics.yOffset + opticalYOffset
        )
    }

    private static func opticalDateTextMetrics(for day: Int) -> DateTextMetrics {
        // These are intentionally tiny, icon-style optical corrections. Calendar
        // dates have only 31 states, and centering the live text mathematically
        // still leaves days like 1, 11, 17, 30, and 31 looking off at menu-bar size.
        switch day {
        case 1:
            return DateTextMetrics(fontSize: 10.8, tracking: 0, xOffset: 0.18, yOffset: -0.1)
        case 2, 3, 5, 6, 8, 9:
            return DateTextMetrics(fontSize: 10.5, tracking: 0, xOffset: 0.18, yOffset: -0.05)
        case 4, 7:
            return DateTextMetrics(fontSize: 10.35, tracking: 0, xOffset: 0.18, yOffset: -0.05)
        case 10, 20, 30:
            return DateTextMetrics(fontSize: 9.45, tracking: -0.15, xOffset: 0, yOffset: -0.05)
        case 11:
            return DateTextMetrics(fontSize: 9.9, tracking: 0.35, xOffset: 0, yOffset: -0.05)
        case 12, 13, 15, 16, 18, 19:
            return DateTextMetrics(fontSize: 9.55, tracking: -0.05, xOffset: 0, yOffset: -0.05)
        case 14:
            return DateTextMetrics(fontSize: 9.45, tracking: -0.1, xOffset: 0, yOffset: -0.05)
        case 17:
            return DateTextMetrics(fontSize: 9.55, tracking: 0.1, xOffset: 0, yOffset: -0.05)
        case 21, 31:
            return DateTextMetrics(fontSize: 9.65, tracking: -0.05, xOffset: 0, yOffset: -0.05)
        case 22, 23, 25, 26, 28, 29:
            return DateTextMetrics(fontSize: 9.5, tracking: -0.1, xOffset: 0, yOffset: -0.05)
        case 24, 27:
            return DateTextMetrics(fontSize: 9.4, tracking: -0.15, xOffset: 0, yOffset: -0.05)
        default:
            return DateTextMetrics(fontSize: 9.5, tracking: -0.1, xOffset: 0, yOffset: -0.05)
        }
    }

    private static func drawInkCentered(
        _ attributedString: NSAttributedString,
        in rect: NSRect,
        opticalXOffset: CGFloat,
        opticalYOffset: CGFloat
    ) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            attributedString.draw(in: rect)
            return
        }

        let line = CTLineCreateWithAttributedString(attributedString)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let advanceWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        let glyphBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])

        guard advanceWidth.isFinite,
              ascent.isFinite,
              descent.isFinite,
              glyphBounds.origin.x.isFinite,
              glyphBounds.origin.y.isFinite,
              glyphBounds.width.isFinite,
              glyphBounds.height.isFinite,
              advanceWidth > 0,
              glyphBounds.width > 0,
              glyphBounds.height > 0
        else {
            attributedString.draw(in: rect)
            return
        }

        let rawTextPosition = CGPoint(
            x: rect.midX - glyphBounds.midX + opticalXOffset,
            y: rect.midY - glyphBounds.midY + opticalYOffset
        )
        let textPosition = CGPoint(
            x: rawTextPosition.x,
            y: pixelSnapped(rawTextPosition.y)
        )

        context.saveGState()
        context.setShouldAntialias(true)
        context.setShouldSmoothFonts(true)
        context.textMatrix = .identity
        context.textPosition = textPosition
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func pixelSnapped(_ rect: NSRect) -> NSRect {
        NSRect(
            x: pixelSnapped(rect.origin.x),
            y: pixelSnapped(rect.origin.y),
            width: pixelSnapped(rect.width),
            height: pixelSnapped(rect.height)
        )
    }

    private static func pixelSnapped(_ point: CGPoint) -> CGPoint {
        CGPoint(x: pixelSnapped(point.x), y: pixelSnapped(point.y))
    }

    private static func pixelSnapped(_ value: CGFloat) -> CGFloat {
        let scale = backingScale()
        return (value * scale).rounded() / scale
    }

    private static func backingScale() -> CGFloat {
        guard let context = NSGraphicsContext.current else {
            return NSScreen.main?.backingScaleFactor ?? 2
        }

        let transform = context.cgContext.userSpaceToDeviceSpaceTransform
        let scale = max(abs(transform.a), abs(transform.d))
        guard scale.isFinite, scale > 0 else {
            return NSScreen.main?.backingScaleFactor ?? 2
        }

        return scale
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

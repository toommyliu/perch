import AppKit
import XCTest
@testable import Perch

final class MenuIconRendererTests: XCTestCase {
    func testDateIconKeepsExpectedSizeAndRendersContent() {
        for day in 1...31 {
            let image = MenuIconRenderer.dateIcon(day: day)

            XCTAssertEqual(image.size, NSSize(width: 22, height: 19))
            XCTAssertTrue(imageHasVisibleContent(image), "Expected day \(day) icon to render visible content")
        }
    }

    #if DEBUG
    func testDateIconRendersWithDebugFontWeights() {
        for fontWeight in DateIconDebugFontWeight.allCases {
            let image = MenuIconRenderer.dateIcon(
                day: 31,
                options: DateIconRenderOptions(
                    fontWeight: fontWeight.nsFontWeight,
                    opticalYOffset: 0
                )
            )

            XCTAssertEqual(image.size, NSSize(width: 22, height: 19))
            XCTAssertTrue(imageHasVisibleContent(image), "Expected \(fontWeight.displayTitle) icon to render visible content")
        }
    }
    #endif

    private func imageHasVisibleContent(_ image: NSImage) -> Bool {
        var proposedRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            return false
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        for x in 0..<bitmap.pixelsWide {
            for y in 0..<bitmap.pixelsHigh {
                if let color = bitmap.colorAt(x: x, y: y), color.alphaComponent > 0.01 {
                    return true
                }
            }
        }

        return false
    }
}

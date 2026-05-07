import XCTest
@testable import Perch

final class ZoomMeetingLinkExtractorTests: XCTestCase {
    private let extractor = ZoomMeetingLinkExtractor()

    func testExtractsZoomMeetingFromLocation() {
        let url = extractor.meetingURL(from: [
            nil,
            "Join at https://school.zoom.us/j/1234567890?pwd=abc",
            nil
        ])

        XCTAssertEqual(url?.absoluteString, "https://school.zoom.us/j/1234567890?pwd=abc")
    }

    func testExtractsZoomMeetingFromNotesWhenURLFieldIsNotZoom() {
        let url = extractor.meetingURL(from: [
            "https://example.com/event",
            nil,
            "Zoom: https://us02web.zoom.us/my/professor"
        ])

        XCTAssertEqual(url?.absoluteString, "https://us02web.zoom.us/my/professor")
    }

    func testRejectsNonZoomAndLookalikeHosts() {
        let url = extractor.meetingURL(from: [
            "https://zoom.us.evil.example/j/1234567890",
            "https://example.com/zoom.us/j/1234567890"
        ])

        XCTAssertNil(url)
    }
}

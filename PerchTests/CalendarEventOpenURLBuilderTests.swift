import XCTest
@testable import Perch

final class CalendarEventOpenURLBuilderTests: XCTestCase {
    func testBuildsCalendarEventURLWithUTCStartDateAndEncodedIdentifier() {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: -7 * 60 * 60)
        components.year = 2026
        components.month = 5
        components.day = 6
        components.hour = 10
        components.minute = 30

        let url = CalendarEventOpenURLBuilder().url(
            eventIdentifier: "event/id 50%",
            startDate: components.date!
        )

        XCTAssertEqual(
            url?.absoluteString,
            "ical://ekevent/20260506T173000Z/event%2Fid%2050%25?method=show&options=more"
        )
    }

    func testReturnsNilForEmptyIdentifier() {
        XCTAssertNil(CalendarEventOpenURLBuilder().url(eventIdentifier: "", startDate: Date()))
    }
}

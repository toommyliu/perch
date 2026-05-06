import AppKit
import XCTest
@testable import Dayline

final class MenuBuilderTests: XCTestCase {
    private let builder = MenuBuilder()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    func testEventsGroupIntoTodayTomorrowAndDateHeadings() {
        let now = date(day: 6, hour: 9, minute: 0)
        let events = [
            event(title: "Today Event", start: date(day: 6, hour: 10, minute: 0), end: date(day: 6, hour: 11, minute: 0)),
            event(title: "Tomorrow Event", start: date(day: 7, hour: 10, minute: 0), end: date(day: 7, hour: 11, minute: 0)),
            event(title: "Later Event", start: date(day: 8, hour: 10, minute: 0), end: date(day: 8, hour: 11, minute: 0))
        ]

        let snapshot = builder.snapshot(accessState: .fullAccess, events: events, now: now, calendar: calendar)

        XCTAssertEqual(snapshot.sections.map(\.title), ["Today", "Tomorrow", "Fri May 8"])
    }

    func testPastEndedEventsAreExcludedAndOngoingEventsRemainVisible() {
        let now = date(day: 6, hour: 9, minute: 30)
        let events = [
            event(title: "Past", start: date(day: 6, hour: 8, minute: 0), end: date(day: 6, hour: 9, minute: 0)),
            event(title: "Current", start: date(day: 6, hour: 9, minute: 0), end: date(day: 6, hour: 10, minute: 0))
        ]

        let snapshot = builder.snapshot(accessState: .fullAccess, events: events, now: now, calendar: calendar)

        XCTAssertEqual(snapshot.sections.count, 1)
        XCTAssertEqual(snapshot.sections[0].rows.map(\.title), ["9:00 AM · Current"])
    }

    func testAllDayRowsFormatAsAllDayTitle() {
        let now = date(day: 6, hour: 9, minute: 0)
        let events = [
            CalendarEvent(
                id: "all-day",
                title: "Conference",
                startDate: date(day: 6, hour: 0, minute: 0),
                endDate: date(day: 7, hour: 0, minute: 0),
                isAllDay: true,
                calendarTitle: "School",
                calendarColor: .systemRed
            )
        ]

        let snapshot = builder.snapshot(accessState: .fullAccess, events: events, now: now, calendar: calendar)

        XCTAssertEqual(snapshot.sections[0].rows[0].title, "All day · Conference")
    }

    func testEmptyAuthorizedStateShowsNoUpcomingEvents() {
        let snapshot = builder.snapshot(accessState: .fullAccess, events: [], now: Date(), calendar: calendar)

        XCTAssertEqual(snapshot.sections[0].rows[0].title, "No upcoming events")
        XCTAssertFalse(snapshot.sections[0].rows[0].isEnabled)
    }

    func testDeniedStateShowsPrivacySettingsActions() {
        let snapshot = builder.snapshot(accessState: .denied, events: [], now: Date(), calendar: calendar)

        XCTAssertEqual(snapshot.sections[0].rows.map(\.title), [
            "Calendar access denied",
            "Enable calendar access in System Settings to show upcoming events.",
            "Open Calendar Privacy Settings..."
        ])
        XCTAssertEqual(snapshot.sections[0].rows[2].action, .openPrivacySettings)
    }

    func testWriteOnlyStateShowsFullAccessRequiredAction() {
        let snapshot = builder.snapshot(accessState: .writeOnly, events: [], now: Date(), calendar: calendar)

        XCTAssertEqual(snapshot.sections[0].rows.map(\.title), [
            "Full calendar access required",
            "Dayline can only write calendar events. Enable full access in System Settings so it can read upcoming events.",
            "Open Calendar Privacy Settings..."
        ])
        XCTAssertEqual(snapshot.sections[0].rows[2].action, .openPrivacySettings)
    }

    func testFooterRowsExposeMenuKeyEquivalents() {
        let snapshot = builder.snapshot(accessState: .fullAccess, events: [], now: Date(), calendar: calendar)
        let visibleFooterRows = snapshot.footerRows.filter { !$0.isHidden }

        XCTAssertEqual(visibleFooterRows.map(\.title), ["Open Calendar", "Settings...", "Quit Dayline"])
        XCTAssertEqual(visibleFooterRows[0].keyEquivalent, "1")
        XCTAssertEqual(visibleFooterRows[0].keyEquivalentModifierMask, [.command])

        XCTAssertEqual(visibleFooterRows[1].keyEquivalent, ",")
        XCTAssertEqual(visibleFooterRows[1].keyEquivalentModifierMask, [.command])
    }

    func testCloseMenuShortcutRowIsHiddenButAllowsKeyEquivalent() {
        let snapshot = builder.snapshot(accessState: .fullAccess, events: [], now: Date(), calendar: calendar)

        let closeRow = snapshot.footerRows.first { $0.action == .closeMenu }
        XCTAssertEqual(closeRow?.title, "Close Menu")
        XCTAssertEqual(closeRow?.keyEquivalent, TrayMenuHotKey.keyEquivalent)
        XCTAssertEqual(closeRow?.keyEquivalentModifierMask, TrayMenuHotKey.menuModifierFlags)
        XCTAssertEqual(closeRow?.isHidden, true)
        XCTAssertEqual(closeRow?.allowsKeyEquivalentWhenHidden, true)
    }

    private func event(title: String, start: Date, end: Date) -> CalendarEvent {
        CalendarEvent(
            id: UUID().uuidString,
            title: title,
            startDate: start,
            endDate: end,
            isAllDay: false,
            calendarTitle: "School",
            calendarColor: .systemBlue
        )
    }

    private func date(day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2026
        components.month = 5
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date!
    }
}

final class TrayMenuHotKeyTests: XCTestCase {
    func testControlCommandKMatchesMenuEvent() {
        XCTAssertTrue(TrayMenuHotKey.matchesMenuEvent(keyEvent(modifierFlags: [.command, .control])))
    }

    func testCommandKDoesNotMatchMenuEvent() {
        XCTAssertFalse(TrayMenuHotKey.matchesMenuEvent(keyEvent(modifierFlags: [.command])))
    }

    func testControlKDoesNotMatchMenuEvent() {
        XCTAssertFalse(TrayMenuHotKey.matchesMenuEvent(keyEvent(modifierFlags: [.control])))
    }

    func testControlCommandShiftKDoesNotMatchMenuEvent() {
        XCTAssertFalse(TrayMenuHotKey.matchesMenuEvent(keyEvent(modifierFlags: [.command, .control, .shift])))
    }

    func testControlCommandOptionKDoesNotMatchMenuEvent() {
        XCTAssertFalse(TrayMenuHotKey.matchesMenuEvent(keyEvent(modifierFlags: [.command, .control, .option])))
    }

    func testControlCommandKWithCapsLockMatchesMenuEvent() {
        XCTAssertTrue(TrayMenuHotKey.matchesMenuEvent(keyEvent(modifierFlags: [.command, .control, .capsLock])))
    }

    private func keyEvent(modifierFlags: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifierFlags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: TrayMenuHotKey.keyEquivalent,
            charactersIgnoringModifiers: TrayMenuHotKey.keyEquivalent,
            isARepeat: false,
            keyCode: UInt16(TrayMenuHotKey.carbonKeyCode)
        )!
    }
}

import AppKit
import Foundation

enum CalendarEventResponseStatus {
    case yes
    case no
    case maybe
}

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColor: NSColor
    let zoomMeetingURL: URL?
    let responseStatus: CalendarEventResponseStatus?

    init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendarTitle: String,
        calendarColor: NSColor,
        zoomMeetingURL: URL? = nil,
        responseStatus: CalendarEventResponseStatus? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarTitle = calendarTitle
        self.calendarColor = calendarColor
        self.zoomMeetingURL = zoomMeetingURL
        self.responseStatus = responseStatus
    }
}

extension CalendarEvent: Equatable {
    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.startDate == rhs.startDate
            && lhs.endDate == rhs.endDate
            && lhs.isAllDay == rhs.isAllDay
            && lhs.calendarTitle == rhs.calendarTitle
            && lhs.calendarColor.isEqual(rhs.calendarColor)
            && lhs.zoomMeetingURL == rhs.zoomMeetingURL
            && lhs.responseStatus == rhs.responseStatus
    }
}

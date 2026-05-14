import AppKit
import Foundation

struct CalendarInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let sourceTitle: String
    let color: NSColor

    static func == (lhs: CalendarInfo, rhs: CalendarInfo) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.sourceTitle == rhs.sourceTitle
            && lhs.color.isEqual(rhs.color)
    }
}

protocol CalendarPermissionProviding {
    func authorizationState() -> CalendarAccessState
    func requestFullAccess() async -> CalendarAccessState
}

protocol CalendarEventProviding {
    func availableCalendars() async throws -> [CalendarInfo]
    func events(
        from startDate: Date,
        to endDate: Date,
        calendarIdentifiers: Set<String>?
    ) async throws -> [CalendarEvent]
}

typealias CalendarProviding = CalendarPermissionProviding & CalendarEventProviding

import AppKit
import EventKit
import Foundation

final class EventKitCalendarProvider: CalendarProviding {
    private let eventStore: EKEventStore
    private let zoomMeetingLinkExtractor = ZoomMeetingLinkExtractor()

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
        PerchLog.info("EventKitCalendarProvider initialized")
    }

    func authorizationState() -> CalendarAccessState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .fullAccess, .authorized:
            return .fullAccess
        case .writeOnly:
            return .writeOnly
        @unknown default:
            return .unknown
        }
    }

    func requestFullAccess() async -> CalendarAccessState {
        let granted: Bool

        do {
            granted = try await eventStore.requestFullAccessToEvents()
        } catch {
            PerchLog.error("Calendar full access request failed: \(error.localizedDescription)")
            return authorizationState()
        }

        PerchLog.info("Calendar full access request completed: \(granted)")
        return granted ? .fullAccess : authorizationState()
    }

    func availableCalendars() async throws -> [CalendarInfo] {
        eventStore.calendars(for: .event)
            .map { calendar in
                CalendarInfo(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    sourceTitle: calendar.source.title,
                    color: NSColor(cgColor: calendar.cgColor) ?? .controlAccentColor
                )
            }
            .sorted(by: Self.isOrderedBefore)
    }

    func events(
        from startDate: Date,
        to endDate: Date,
        calendarIdentifiers: Set<String>?
    ) async throws -> [CalendarEvent] {
        if calendarIdentifiers?.isEmpty == true {
            return []
        }

        let calendars = eventStore.calendars(for: .event)
            .filter { calendar in
                calendarIdentifiers?.contains(calendar.calendarIdentifier) ?? true
            }
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

        return eventStore.events(matching: predicate)
            .filter { $0.status != .canceled }
            .map { event in
                CalendarEvent(
                    id: event.calendarItemIdentifier,
                    title: event.title?.isEmpty == false ? event.title : "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarTitle: event.calendar.title,
                    calendarColor: NSColor(cgColor: event.calendar.cgColor) ?? .controlAccentColor,
                    calendarIdentifier: event.calendar.calendarIdentifier,
                    zoomMeetingURL: zoomMeetingLinkExtractor.meetingURL(from: [
                        event.url?.absoluteString,
                        event.location,
                        event.notes
                    ]),
                    responseStatus: Self.responseStatus(for: event)
                )
            }
            .sorted {
                if $0.startDate != $1.startDate {
                    return $0.startDate < $1.startDate
                }

                if $0.endDate != $1.endDate {
                    return $0.endDate < $1.endDate
                }

                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
    }

    private static func isOrderedBefore(_ lhs: CalendarInfo, _ rhs: CalendarInfo) -> Bool {
        let sourceComparison = lhs.sourceTitle.localizedCaseInsensitiveCompare(rhs.sourceTitle)
        if sourceComparison != .orderedSame {
            return sourceComparison == .orderedAscending
        }

        let titleComparison = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if titleComparison != .orderedSame {
            return titleComparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }

    private static func responseStatus(for event: EKEvent) -> CalendarEventResponseStatus? {
        guard let currentUser = event.attendees?.first(where: { $0.isCurrentUser }) else {
            return nil
        }

        switch currentUser.participantStatus {
        case .accepted:
            return .yes
        case .declined:
            return .no
        case .tentative:
            return .maybe
        case .unknown, .pending, .delegated, .completed, .inProcess:
            return nil
        @unknown default:
            return nil
        }
    }
}

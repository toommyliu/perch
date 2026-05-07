import Foundation

enum CalendarEventVisibility {
    static func upcomingEvents(
        from events: [CalendarEvent],
        includeAllDayEvents: Bool,
        now: Date
    ) -> [CalendarEvent] {
        events
            .filter { event in
                event.endDate >= now && (includeAllDayEvents || !event.isAllDay)
            }
            .sorted(by: isOrderedBefore)
    }

    private static func isOrderedBefore(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        if lhs.startDate != rhs.startDate {
            return lhs.startDate < rhs.startDate
        }

        if lhs.endDate != rhs.endDate {
            return lhs.endDate < rhs.endDate
        }

        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

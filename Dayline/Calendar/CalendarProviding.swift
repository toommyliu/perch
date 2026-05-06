import Foundation

protocol CalendarProviding {
    func authorizationState() -> CalendarAccessState
    func requestFullAccess() async -> CalendarAccessState
    func events(from startDate: Date, to endDate: Date) async throws -> [CalendarEvent]
}

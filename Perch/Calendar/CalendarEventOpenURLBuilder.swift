import Foundation

struct CalendarEventOpenURLBuilder {
    func url(eventIdentifier: String, startDate: Date) -> URL? {
        guard !eventIdentifier.isEmpty else {
            return nil
        }

        let dateString = Self.eventDateString(from: startDate)
        guard let encodedIdentifier = Self.percentEncodedPathSegment(eventIdentifier) else {
            return nil
        }

        return URL(string: "ical://ekevent/\(dateString)/\(encodedIdentifier)?method=show&options=more")
    }

    private static func eventDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }

    private static func percentEncodedPathSegment(_ value: String) -> String? {
        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/%?#[]@!$&'()*+,;=")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}

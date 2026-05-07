import Foundation

struct ZoomMeetingLinkExtractor {
    func meetingURL(from strings: [String?]) -> URL? {
        for string in strings.compactMap(\.self) {
            if let url = meetingURL(from: string) {
                return url
            }
        }

        return nil
    }

    private func meetingURL(from string: String) -> URL? {
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }

        for match in detector.matches(in: string, options: [], range: range) {
            guard let url = match.url,
                  isZoomMeetingURL(url)
            else {
                continue
            }

            return url
        }

        return nil
    }

    private func isZoomMeetingURL(_ url: URL) -> Bool {
        let scheme = url.scheme?.lowercased()
        if scheme == "zoommtg" || scheme == "zoomus" {
            return true
        }

        guard scheme == "http" || scheme == "https",
              let host = url.host?.lowercased(),
              host == "zoom.us" || host.hasSuffix(".zoom.us")
        else {
            return false
        }

        let path = url.path.lowercased()
        return path.contains("/j/")
            || path.contains("/my/")
            || path.contains("/w/")
    }
}

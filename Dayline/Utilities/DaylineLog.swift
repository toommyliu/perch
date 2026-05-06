import Foundation
import os

enum DaylineLog {
    private static let logger = Logger(subsystem: "com.app.dayline", category: "app")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        FileHandle.standardError.write("[Dayline] \(message)\n".data(using: .utf8) ?? Data())
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        FileHandle.standardError.write("[Dayline] ERROR: \(message)\n".data(using: .utf8) ?? Data())
    }
}

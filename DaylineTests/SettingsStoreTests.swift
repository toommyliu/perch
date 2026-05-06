import Foundation
import XCTest
@testable import Dayline

final class SettingsStoreTests: XCTestCase {
    func testDefaultDisplayModeIsWithinSixHours() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.settings.displayMode, .within6Hours)
        XCTAssertEqual(store.settings.lookAheadDays, 3)
    }

    func testPersistedDisplayModeRoundTripsThroughUserDefaults() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.updateDisplayMode(.always)

        let reloadedStore = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloadedStore.settings.displayMode, .always)
    }

    func testPersistedLookAheadDaysRoundTripsThroughUserDefaults() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.updateLookAheadDays(14)

        let reloadedStore = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloadedStore.settings.lookAheadDays, 14)
    }

    func testUnsupportedLookAheadDaysAreIgnored() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.updateLookAheadDays(2)

        XCTAssertEqual(store.settings.lookAheadDays, 3)
    }

    func testInvalidStoredValuesFallBackToDefaults() {
        let defaults = makeDefaults()
        defaults.set(Data("not-json".utf8), forKey: "CalendarMenubarSettings")

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.settings, .defaultValue)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "DaylineTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

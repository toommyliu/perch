import XCTest
@testable import Dayline

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testInitializesWithSettingsAndPermissionState() {
        let defaults = makeDefaults()
        let settingsStore = SettingsStore(userDefaults: defaults)
        settingsStore.updateDisplayMode(.always)
        settingsStore.updateLookAheadDays(14)
        let provider = FakePermissionProvider(state: .writeOnly)
        let permissionController = CalendarPermissionController(permissionProvider: provider)

        let model = SettingsViewModel(
            settingsStore: settingsStore,
            permissionController: permissionController,
            onChange: {}
        )

        XCTAssertEqual(model.selectedMode, .always)
        XCTAssertEqual(model.lookAheadDays, 14)
        XCTAssertEqual(model.accessState, .writeOnly)
        XCTAssertEqual(model.accessActionTitle, "Open Privacy Settings...")
    }

    func testRequestCalendarAccessUpdatesPermissionState() async {
        let settingsStore = SettingsStore(userDefaults: makeDefaults())
        let provider = FakePermissionProvider(state: .notDetermined, requestResult: .fullAccess)
        let permissionController = CalendarPermissionController(permissionProvider: provider)
        var changeCount = 0
        let model = SettingsViewModel(
            settingsStore: settingsStore,
            permissionController: permissionController
        ) {
            changeCount += 1
        }

        model.requestCalendarAccess()
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(model.accessState, .fullAccess)
        XCTAssertFalse(model.isRequestingAccess)
        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(changeCount, 1)
    }

    func testPrivacySettingsActionInvokesURLOpener() {
        let settingsStore = SettingsStore(userDefaults: makeDefaults())
        let provider = FakePermissionProvider(state: .denied)
        var openedURLs: [URL] = []
        let permissionController = CalendarPermissionController(permissionProvider: provider) { url in
            openedURLs.append(url)
        }
        let model = SettingsViewModel(
            settingsStore: settingsStore,
            permissionController: permissionController,
            onChange: {}
        )

        model.performAccessAction()

        XCTAssertEqual(openedURLs, [CalendarPermissionController.privacySettingsURL])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "DaylineTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

final class FakePermissionProvider: CalendarPermissionProviding {
    var state: CalendarAccessState
    var requestResult: CalendarAccessState
    private(set) var requestCount = 0

    init(state: CalendarAccessState, requestResult: CalendarAccessState? = nil) {
        self.state = state
        self.requestResult = requestResult ?? state
    }

    func authorizationState() -> CalendarAccessState {
        state
    }

    func requestFullAccess() async -> CalendarAccessState {
        requestCount += 1
        state = requestResult
        return requestResult
    }
}

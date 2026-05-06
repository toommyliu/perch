import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var refreshCoordinator: CalendarRefreshCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DaylineLog.info("Application did finish launching")
        NSApp.setActivationPolicy(.accessory)

        let settingsStore = SettingsStore()
        let settingsWindowController = SettingsWindowController(settingsStore: settingsStore)
        let menuBarController = MenuBarController(
            calendarProvider: EventKitCalendarProvider(),
            settingsStore: settingsStore,
            settingsWindowController: settingsWindowController
        )

        let refreshCoordinator = CalendarRefreshCoordinator {
            menuBarController.refresh()
        }

        self.menuBarController = menuBarController
        self.refreshCoordinator = refreshCoordinator

        refreshCoordinator.start()
        menuBarController.refresh()
        DaylineLog.info("Application setup complete")
    }

    func applicationWillTerminate(_ notification: Notification) {
        DaylineLog.info("Application will terminate")
        refreshCoordinator?.stop()
    }
}

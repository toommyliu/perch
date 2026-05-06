import AppKit
import Foundation

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let calendarProvider: CalendarProviding
    private let settingsStore: SettingsStore
    private let settingsWindowController: SettingsWindowController
    private let labelFormatter = MenuBarLabelFormatter()
    private let menuBuilder = MenuBuilder()
    private var events: [CalendarEvent] = []
    private var isTrayMenuOpen = false
    var onTrayMenuWillOpen: (() -> Void)?
    var onTrayMenuDidClose: (() -> Void)?

    init(
        calendarProvider: CalendarProviding,
        settingsStore: SettingsStore,
        settingsWindowController: SettingsWindowController
    ) {
        self.calendarProvider = calendarProvider
        self.settingsStore = settingsStore
        self.settingsWindowController = settingsWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        DaylineLog.info("MenuBarController initialized")

        settingsWindowController.onSettingsChanged = { [weak self] in
            Task { @MainActor in
                DaylineLog.info("Settings changed; refreshing calendar data")
                await self?.refreshCalendarData()
            }
        }

        configureStatusItem()
        updateMenu(accessState: calendarProvider.authorizationState())
        updateStatusItem()
    }

    func refresh() {
        Task {
            await refreshCalendarData()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            DaylineLog.error("Status item has no button")
            return
        }

        button.imagePosition = .imageLeading
        button.toolTip = "Dayline"
        button.title = ""
        DaylineLog.info("Status item configured")
    }

    private func refreshCalendarData() async {
        let accessState = calendarProvider.authorizationState()
        DaylineLog.info("Refresh started with access state: \(String(describing: accessState))")

        guard accessState == .fullAccess else {
            events = []
            updateStatusItem()
            updateMenu(accessState: accessState)
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let settings = settingsStore.settings
        let startDate = calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: settings.lookAheadDays, to: startDate) ?? now.addingTimeInterval(7 * 24 * 60 * 60)

        do {
            events = try await calendarProvider.events(from: startDate, to: endDate)
            DaylineLog.info("Fetched \(events.count) events")
        } catch {
            events = []
            DaylineLog.error("Failed to fetch events: \(error.localizedDescription)")
        }

        updateStatusItem()
        updateMenu(accessState: accessState)
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        let content = labelFormatter.labelContent(events: events, settings: settingsStore.settings)

        switch content {
        case let .dateIcon(day):
            statusItem.length = 30
            button.title = ""
            button.image = MenuIconRenderer.dateIcon(day: day)
            DaylineLog.info("Status item set to date icon for day \(day)")
        case let .event(title, relativeText, color):
            statusItem.length = NSStatusItem.variableLength
            button.image = MenuIconRenderer.colorBar(color: color)
            button.title = " \(title) · \(relativeText)"
            DaylineLog.info("Status item set to event: \(title) · \(relativeText)")
        }
    }

    private func updateMenu(accessState: CalendarAccessState) {
        let snapshot = menuBuilder.snapshot(accessState: accessState, events: events)
        let menu = menuBuilder.makeMenu(from: snapshot, target: self)
        menu.delegate = self
        statusItem.menu = menu
        DaylineLog.info("Menu updated with \(snapshot.sections.count) sections and access state: \(String(describing: accessState))")
    }

    func toggleTrayVisibility() {
        if isTrayMenuOpen {
            DaylineLog.info("Closing tray menu from global hotkey")
            statusItem.menu?.cancelTracking()
            return
        }

        guard let button = statusItem.button else {
            DaylineLog.error("Cannot open tray menu because status item has no button")
            return
        }

        DaylineLog.info("Opening tray menu from global hotkey")
        button.performClick(nil)
    }

    @objc func closeTrayMenuFromMenuItem() {
        DaylineLog.info("Closing tray menu from menu key equivalent")
        statusItem.menu?.cancelTracking()
    }

    @objc func requestCalendarAccess() {
        DaylineLog.info("Calendar access requested from menu")
        Task {
            _ = await calendarProvider.requestFullAccess()
            await refreshCalendarData()
        }
    }

    @objc func openCalendarPrivacySettings() {
        DaylineLog.info("Opening Calendar privacy settings")
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    @objc func openCalendarApp() {
        DaylineLog.info("Opening Apple Calendar")
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else {
            DaylineLog.error("Could not resolve Apple Calendar bundle id")
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }

    @objc func openSettings() {
        DaylineLog.info("Opening settings window")
        settingsWindowController.present()
    }

    @objc func quit() {
        DaylineLog.info("Quit requested")
        NSApp.terminate(nil)
    }
}

extension MenuBarController: NSMenuDelegate {
    nonisolated func menuWillOpen(_ menu: NSMenu) {
        updateTrayMenuOpenState(true)
    }

    nonisolated func menuDidClose(_ menu: NSMenu) {
        updateTrayMenuOpenState(false)
    }

    private nonisolated func updateTrayMenuOpenState(_ isOpen: Bool) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                isTrayMenuOpen = isOpen
                if isOpen {
                    onTrayMenuWillOpen?()
                } else {
                    onTrayMenuDidClose?()
                }
            }
        } else {
            Task { @MainActor in
                isTrayMenuOpen = isOpen
                if isOpen {
                    onTrayMenuWillOpen?()
                } else {
                    onTrayMenuDidClose?()
                }
            }
        }
    }
}

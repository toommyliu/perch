import AppKit
import Carbon
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedMode: MenuBarDisplayMode {
        didSet {
            settingsStore.updateDisplayMode(selectedMode)
            onChange()
        }
    }

    @Published var lookAheadDays: Int {
        didSet {
            settingsStore.updateLookAheadDays(lookAheadDays)
            onChange()
        }
    }

    @Published var showEventColors: Bool {
        didSet {
            settingsStore.updateShowEventColors(showEventColors)
            onChange()
        }
    }

    @Published var showAllDayEvents: Bool {
        didSet {
            settingsStore.updateShowAllDayEvents(showAllDayEvents)
            onChange()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard !isApplyingLoginItemState else {
                return
            }

            applyLaunchAtLoginChange()
        }
    }

    #if DEBUG
    @Published var debugDateIconOverrideEnabled: Bool {
        didSet {
            dateIconDebugSettings?.isOverrideEnabled = debugDateIconOverrideEnabled
        }
    }

    @Published var debugDateIconDay: Int {
        didSet {
            guard !isApplyingDebugDateClamp else {
                return
            }

            let clampedDay = min(max(debugDateIconDay, 1), 31)
            if debugDateIconDay != clampedDay {
                dateIconDebugSettings?.day = clampedDay
                isApplyingDebugDateClamp = true
                debugDateIconDay = clampedDay
                isApplyingDebugDateClamp = false
                return
            }

            dateIconDebugSettings?.day = debugDateIconDay
        }
    }

    @Published var debugDateIconFontWeight: DateIconDebugFontWeight {
        didSet {
            dateIconDebugSettings?.fontWeight = debugDateIconFontWeight
        }
    }
    #endif

    @Published private(set) var accessState: CalendarAccessState
    @Published private(set) var isRequestingAccess = false
    @Published private(set) var globalShortcut: GlobalShortcut
    @Published private(set) var shortcutError: String?
    @Published private(set) var loginItemError: String?
    @Published private(set) var availableCalendars: [CalendarInfo] = []
    @Published private(set) var selectedCalendarIdentifiers: Set<String>?
    @Published private(set) var calendarLoadingError: String?

    private let settingsStore: SettingsStore
    private let permissionController: CalendarPermissionController
    private let calendarProvider: CalendarEventProviding?
    private let loginItemManager: LoginItemManaging
    private var isApplyingLoginItemState = false
    #if DEBUG
    private let dateIconDebugSettings: DateIconDebugSettings?
    private var isApplyingDebugDateClamp = false
    #endif
    private let onChange: () -> Void
    private let onShortcutChangeRequested: (GlobalShortcut) -> HotKeyRegistrationResult
    private let onAccessRequestCompleted: () -> Void
    private var accessStateCancellable: AnyCancellable?

    #if DEBUG
    init(
        settingsStore: SettingsStore,
        permissionController: CalendarPermissionController,
        calendarProvider: CalendarEventProviding? = nil,
        loginItemManager: LoginItemManaging = LoginItemManager(),
        dateIconDebugSettings: DateIconDebugSettings? = nil,
        onShortcutChangeRequested: @escaping (GlobalShortcut) -> HotKeyRegistrationResult = { _ in .success },
        onAccessRequestCompleted: @escaping () -> Void = {},
        onChange: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.permissionController = permissionController
        self.calendarProvider = calendarProvider
        self.loginItemManager = loginItemManager
        self.dateIconDebugSettings = dateIconDebugSettings
        self.debugDateIconOverrideEnabled = dateIconDebugSettings?.isOverrideEnabled ?? false
        self.debugDateIconDay = dateIconDebugSettings?.day ?? Calendar.current.component(.day, from: Date())
        self.debugDateIconFontWeight = dateIconDebugSettings?.fontWeight ?? .semibold
        let settings = settingsStore.settings
        self.selectedMode = settings.displayMode
        self.lookAheadDays = settings.lookAheadDays
        self.showEventColors = settings.showEventColors
        self.showAllDayEvents = settings.showAllDayEvents
        self.selectedCalendarIdentifiers = settings.selectedCalendarIdentifiers
        self.launchAtLogin = loginItemManager.isEnabled
        self.globalShortcut = settings.globalShortcut
        self.accessState = permissionController.accessState
        self.onShortcutChangeRequested = onShortcutChangeRequested
        self.onAccessRequestCompleted = onAccessRequestCompleted
        self.onChange = onChange

        subscribeToAccessStateChanges()
        refreshAvailableCalendars()
    }
    #else
    init(
        settingsStore: SettingsStore,
        permissionController: CalendarPermissionController,
        calendarProvider: CalendarEventProviding? = nil,
        loginItemManager: LoginItemManaging = LoginItemManager(),
        onShortcutChangeRequested: @escaping (GlobalShortcut) -> HotKeyRegistrationResult = { _ in .success },
        onAccessRequestCompleted: @escaping () -> Void = {},
        onChange: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.permissionController = permissionController
        self.calendarProvider = calendarProvider
        self.loginItemManager = loginItemManager
        let settings = settingsStore.settings
        self.selectedMode = settings.displayMode
        self.lookAheadDays = settings.lookAheadDays
        self.showEventColors = settings.showEventColors
        self.showAllDayEvents = settings.showAllDayEvents
        self.selectedCalendarIdentifiers = settings.selectedCalendarIdentifiers
        self.launchAtLogin = loginItemManager.isEnabled
        self.globalShortcut = settings.globalShortcut
        self.accessState = permissionController.accessState
        self.onShortcutChangeRequested = onShortcutChangeRequested
        self.onAccessRequestCompleted = onAccessRequestCompleted
        self.onChange = onChange

        subscribeToAccessStateChanges()
        refreshAvailableCalendars()
    }
    #endif

    private func subscribeToAccessStateChanges() {
        accessStateCancellable = permissionController.$accessState
            .sink { [weak self] accessState in
                self?.accessState = accessState
                self?.refreshAvailableCalendars()
            }
    }

    func refreshAvailableCalendars() {
        guard accessState.isSufficientForReadingEvents else {
            availableCalendars = []
            calendarLoadingError = nil
            return
        }

        guard let calendarProvider else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                availableCalendars = try await calendarProvider.availableCalendars()
                calendarLoadingError = nil
            } catch {
                availableCalendars = []
                calendarLoadingError = "Could not load calendars."
            }
        }
    }

    func isCalendarSelected(_ calendar: CalendarInfo) -> Bool {
        selectedCalendarIdentifiers?.contains(calendar.id) ?? true
    }

    func setCalendar(_ calendar: CalendarInfo, isSelected: Bool) {
        guard !availableCalendars.isEmpty else {
            return
        }

        var selectedIdentifiers = selectedCalendarIdentifiers ?? Set(availableCalendars.map(\.id))

        if isSelected {
            selectedIdentifiers.insert(calendar.id)
        } else {
            selectedIdentifiers.remove(calendar.id)
        }

        applySelectedCalendarIdentifiers(selectedIdentifiers)
    }

    func selectAllCalendars() {
        applySelectedCalendarIdentifiers(nil)
    }

    func selectNoCalendars() {
        applySelectedCalendarIdentifiers([])
    }

    private func applySelectedCalendarIdentifiers(_ selectedIdentifiers: Set<String>?) {
        selectedCalendarIdentifiers = selectedIdentifiers
        settingsStore.updateSelectedCalendarIdentifiers(selectedIdentifiers)
        onChange()
    }

    var accessActionTitle: String? {
        switch accessState.settingsAction {
        case .requestAccess:
            return "Allow Access..."
        case .openPrivacySettings:
            return "Open Privacy Settings..."
        case nil:
            return nil
        }
    }

    func performAccessAction() {
        switch accessState.settingsAction {
        case .requestAccess:
            requestCalendarAccess()
        case .openPrivacySettings:
            openCalendarPrivacySettings()
        case nil:
            break
        }
    }

    func requestCalendarAccess() {
        guard !isRequestingAccess else {
            return
        }

        isRequestingAccess = true

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            _ = await permissionController.requestFullAccess()
            isRequestingAccess = false
            refreshAvailableCalendars()
            onAccessRequestCompleted()
            onChange()
        }
    }

    func openCalendarPrivacySettings() {
        permissionController.openPrivacySettings()
    }

    private func applyLaunchAtLoginChange() {
        do {
            try loginItemManager.setEnabled(launchAtLogin)
            loginItemError = nil
        } catch {
            loginItemError = "Could not update launch at login."
        }

        refreshLaunchAtLoginState()
    }

    func refreshLaunchAtLoginState() {
        isApplyingLoginItemState = true
        launchAtLogin = loginItemManager.isEnabled
        isApplyingLoginItemState = false
    }

    func recordShortcut(from event: NSEvent) {
        guard let candidate = GlobalShortcut.candidate(from: event) else {
            shortcutError = "Press a printable key with Command, Control, or Option."
            return
        }

        applyShortcut(candidate)
    }

    func resetShortcutToDefault() {
        applyShortcut(.defaultValue)
    }

    private func applyShortcut(_ candidate: GlobalShortcut) {
        switch onShortcutChangeRequested(candidate) {
        case .success:
            settingsStore.updateGlobalShortcut(candidate)
            globalShortcut = candidate
            shortcutError = nil
            onChange()
        case .failure:
            shortcutError = "Shortcut is already in use."
        }
    }
}

struct SettingsView: View {
    private static let contentWidth: CGFloat = 660

    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                GridRow(alignment: .top) {
                    Text("Calendar Access")
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(model.accessState.statusTitle)
                                .font(.body.weight(.medium))

                            if model.accessState.isSufficientForReadingEvents {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }

                        Text(model.accessState.statusDetail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let actionTitle = model.accessActionTitle {
                            Button(actionTitle) {
                                model.performAccessAction()
                            }
                            .disabled(model.isRequestingAccess)
                        }
                    }
                }

                Divider()
                    .gridCellColumns(2)

                GridRow(alignment: .top) {
                    Text("Calendars")
                    VStack(alignment: .leading, spacing: 8) {
                        calendarSelectionHeader

                        if let calendarLoadingError = model.calendarLoadingError {
                            Text(calendarLoadingError)
                                .font(.callout)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if model.availableCalendars.isEmpty {
                            Text(model.accessState.isSufficientForReadingEvents ? "No calendars found" : "Calendar access required")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(model.availableCalendars) { calendar in
                                        Toggle(isOn: Binding(
                                            get: { model.isCalendarSelected(calendar) },
                                            set: { model.setCalendar(calendar, isSelected: $0) }
                                        )) {
                                            HStack(alignment: .top, spacing: 8) {
                                                Circle()
                                                    .fill(Color(nsColor: calendar.color))
                                                    .frame(width: 8, height: 8)
                                                    .padding(.top, 5)

                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text(calendar.title)
                                                        .lineLimit(1)
                                                    Text(calendar.sourceTitle)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                        .toggleStyle(.checkbox)
                                        .frame(minHeight: 34, alignment: .leading)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 2)
                            }
                            .frame(height: calendarListHeight)
                        }
                    }
                }

                Divider()
                    .gridCellColumns(2)

                GridRow {
                    Text("Include events")
                    Picker("Include events", selection: $model.lookAheadDays) {
                        ForEach(CalendarMenubarSettings.supportedLookAheadDays, id: \.self) { days in
                            Text("\(days) \(days == 1 ? "day" : "days")").tag(days)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                GridRow {
                    Text("Menu bar preview")
                    Picker("Menu bar preview", selection: $model.selectedMode) {
                        ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.displayTitle).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                GridRow {
                    Text("Show all-day events")
                    Toggle("Show all-day events", isOn: $model.showAllDayEvents)
                        .labelsHidden()
                }

                GridRow {
                    Text("Show calendar colors")
                    Toggle("Show calendar colors", isOn: $model.showEventColors)
                        .labelsHidden()
                }

                GridRow(alignment: .top) {
                    Text("Launch at login")
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Launch at login", isOn: $model.launchAtLogin)
                            .labelsHidden()

                        if let loginItemError = model.loginItemError {
                            Text(loginItemError)
                                .font(.callout)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                #if DEBUG
                Divider()
                    .gridCellColumns(2)

                GridRow {
                    Text("Debug date icon")
                    Toggle("Debug date icon", isOn: $model.debugDateIconOverrideEnabled)
                        .labelsHidden()
                }

                GridRow {
                    Text("Date")
                    Stepper(value: $model.debugDateIconDay, in: 1...31) {
                        Text("\(model.debugDateIconDay)")
                            .frame(width: 32, alignment: .leading)
                    }
                    .disabled(!model.debugDateIconOverrideEnabled)
                }

                GridRow {
                    Text("Weight")
                    Picker("Weight", selection: $model.debugDateIconFontWeight) {
                        ForEach(DateIconDebugFontWeight.allCases) { weight in
                            Text(weight.displayTitle).tag(weight)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .disabled(!model.debugDateIconOverrideEnabled)
                }
                #endif

                GridRow(alignment: .top) {
                    Text("Open/close menu")
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ShortcutRecorderView(shortcut: model.globalShortcut) { event in
                                model.recordShortcut(from: event)
                            }
                            .frame(width: 150, height: 28)

                            Button("Reset") {
                                model.resetShortcutToDefault()
                            }
                            .disabled(model.globalShortcut == .defaultValue)
                        }

                        if let shortcutError = model.shortcutError {
                            Text(shortcutError)
                                .font(.callout)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: Self.contentWidth)
    }

    private var calendarSelectionHeader: some View {
        HStack(spacing: 8) {
            Text(calendarSelectionSummary)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("All") {
                model.selectAllCalendars()
            }
            .disabled(!model.accessState.isSufficientForReadingEvents || model.selectedCalendarIdentifiers == nil)

            Button("None") {
                model.selectNoCalendars()
            }
            .disabled(!model.accessState.isSufficientForReadingEvents || model.selectedCalendarIdentifiers?.isEmpty == true)
        }
    }

    private var calendarSelectionSummary: String {
        guard model.accessState.isSufficientForReadingEvents else {
            return "Calendar access required"
        }

        return model.selectedCalendarIdentifiers == nil
            ? "All calendars"
            : "\(model.selectedCalendarIdentifiers?.count ?? 0) selected"
    }

    private var calendarListHeight: CGFloat {
        let rowHeight: CGFloat = 40
        let visibleRows = min(max(model.availableCalendars.count, 1), 4)
        return CGFloat(visibleRows) * rowHeight
    }
}

struct ShortcutRecorderView: NSViewRepresentable {
    let shortcut: GlobalShortcut
    let onRecord: (NSEvent) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.target = button
        button.action = #selector(ShortcutRecorderButton.startRecording)
        button.onRecordingChanged = { isRecording in
            context.coordinator.isRecording = isRecording
            updateTitle(for: button, isRecording: isRecording)
        }
        button.onKeyDown = { event in
            guard event.keyCode != UInt16(kVK_Escape) else {
                button.stopRecording()
                return
            }

            onRecord(event)
            button.stopRecording()
        }
        updateTitle(for: button, isRecording: context.coordinator.isRecording)
        return button
    }

    func updateNSView(_ button: ShortcutRecorderButton, context: Context) {
        updateTitle(for: button, isRecording: context.coordinator.isRecording)
    }

    private func updateTitle(for button: ShortcutRecorderButton, isRecording: Bool) {
        button.title = isRecording ? "Type shortcut" : shortcut.displayTitle
    }

    final class Coordinator {
        var isRecording = false
    }
}

final class ShortcutRecorderButton: NSButton {
    var onRecordingChanged: ((Bool) -> Void)?
    var onKeyDown: ((NSEvent) -> Void)?
    private var isRecording = false

    override var acceptsFirstResponder: Bool {
        true
    }

    @objc func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        onRecordingChanged?(true)
    }

    func stopRecording() {
        isRecording = false
        onRecordingChanged?(false)
    }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        onKeyDown?(event)
    }
}

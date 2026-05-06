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
    @Published private(set) var accessState: CalendarAccessState
    @Published private(set) var isRequestingAccess = false

    private let settingsStore: SettingsStore
    private let permissionController: CalendarPermissionController
    private let onChange: () -> Void
    private var accessStateCancellable: AnyCancellable?

    init(
        settingsStore: SettingsStore,
        permissionController: CalendarPermissionController,
        onChange: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.permissionController = permissionController
        let settings = settingsStore.settings
        self.selectedMode = settings.displayMode
        self.lookAheadDays = settings.lookAheadDays
        self.accessState = permissionController.accessState
        self.onChange = onChange

        accessStateCancellable = permissionController.$accessState
            .sink { [weak self] accessState in
                self?.accessState = accessState
            }
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
            onChange()
        }
    }

    func openCalendarPrivacySettings() {
        permissionController.openPrivacySettings()
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
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
                    Text("Preview upcoming event in menu bar")
                    Picker("Preview upcoming event in menu bar", selection: $model.selectedMode) {
                        ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.displayTitle).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
            }
        }
        .padding(20)
        .frame(width: 520)
    }
}

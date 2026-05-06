import SwiftUI

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

    private let settingsStore: SettingsStore
    private let onChange: () -> Void

    init(settingsStore: SettingsStore, onChange: @escaping () -> Void) {
        self.settingsStore = settingsStore
        let settings = settingsStore.settings
        self.selectedMode = settings.displayMode
        self.lookAheadDays = settings.lookAheadDays
        self.onChange = onChange
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
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
        .frame(width: 440)
    }
}

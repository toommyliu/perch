import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Published var selectedMode: MenuBarDisplayMode {
        didSet {
            settingsStore.updateDisplayMode(selectedMode)
            onChange()
        }
    }

    private let settingsStore: SettingsStore
    private let onChange: () -> Void

    init(settingsStore: SettingsStore, onChange: @escaping () -> Void) {
        self.settingsStore = settingsStore
        self.selectedMode = settingsStore.settings.displayMode
        self.onChange = onChange
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Picker("Show upcoming event in menu bar", selection: $model.selectedMode) {
                ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.displayTitle).tag(mode)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(20)
        .frame(width: 380)
    }
}

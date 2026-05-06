import Foundation

struct CalendarMenubarSettings: Codable, Equatable {
    var displayMode: MenuBarDisplayMode
    var lookAheadDays: Int

    static let defaultValue = CalendarMenubarSettings(
        displayMode: .within6Hours,
        lookAheadDays: 7
    )
}

final class SettingsStore {
    private let userDefaults: UserDefaults
    private let settingsKey = "CalendarMenubarSettings"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var settings: CalendarMenubarSettings {
        get {
            guard let data = userDefaults.data(forKey: settingsKey),
                  let decoded = try? JSONDecoder().decode(CalendarMenubarSettings.self, from: data),
                  decoded.lookAheadDays > 0
            else {
                return .defaultValue
            }

            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }

            userDefaults.set(data, forKey: settingsKey)
        }
    }

    func updateDisplayMode(_ displayMode: MenuBarDisplayMode) {
        var currentSettings = settings
        currentSettings.displayMode = displayMode
        settings = currentSettings
    }
}

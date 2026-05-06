import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    var onSettingsChanged: (() -> Void)?

    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 92),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dayline Settings"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let viewModel = SettingsViewModel(settingsStore: settingsStore) { [weak self] in
            self?.onSettingsChanged?()
        }
        window.contentView = NSHostingView(rootView: SettingsView(model: viewModel))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

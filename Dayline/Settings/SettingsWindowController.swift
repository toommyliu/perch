import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    var onSettingsChanged: (() -> Void)?

    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dayline Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false

        super.init(window: window)

        let viewModel = SettingsViewModel(settingsStore: settingsStore) { [weak self] in
            self?.onSettingsChanged?()
        }
        window.contentView = NSHostingView(rootView: SettingsView(model: viewModel))
    }

    @MainActor
    func present() {
        guard let window else {
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        if !window.isVisible {
            window.center()
        }

        NSApp.activate(ignoringOtherApps: true)

        window.level = .floating
        showWindow(nil)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        // Accessory apps can lose the first ordering race when opened from an NSMenu.
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            window.level = .normal
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

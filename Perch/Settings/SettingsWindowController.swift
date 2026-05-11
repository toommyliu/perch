import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    var onSettingsChanged: (() -> Void)?
    var onShortcutChangeRequested: ((GlobalShortcut) -> HotKeyRegistrationResult)?

    private let settingsStore: SettingsStore
    private let permissionController: CalendarPermissionController
    private let loginItemManager: LoginItemManaging

    #if DEBUG
    init(
        settingsStore: SettingsStore,
        permissionController: CalendarPermissionController,
        loginItemManager: LoginItemManaging,
        dateIconDebugSettings: DateIconDebugSettings
    ) {
        self.settingsStore = settingsStore
        self.permissionController = permissionController
        self.loginItemManager = loginItemManager

        let window = Self.makeWindow(height: 430)

        super.init(window: window)

        let viewModel = SettingsViewModel(
            settingsStore: settingsStore,
            permissionController: permissionController,
            loginItemManager: loginItemManager,
            dateIconDebugSettings: dateIconDebugSettings,
            onShortcutChangeRequested: { [weak self] shortcut in
                self?.onShortcutChangeRequested?(shortcut) ?? .failure(OSStatus(-1))
            }
        ) { [weak self] in
            self?.onSettingsChanged?()
        }
        window.contentView = NSHostingView(rootView: SettingsView(model: viewModel))
    }
    #else
    init(
        settingsStore: SettingsStore,
        permissionController: CalendarPermissionController,
        loginItemManager: LoginItemManaging
    ) {
        self.settingsStore = settingsStore
        self.permissionController = permissionController
        self.loginItemManager = loginItemManager

        let window = Self.makeWindow(height: 360)

        super.init(window: window)

        let viewModel = SettingsViewModel(
            settingsStore: settingsStore,
            permissionController: permissionController,
            loginItemManager: loginItemManager,
            onShortcutChangeRequested: { [weak self] shortcut in
                self?.onShortcutChangeRequested?(shortcut) ?? .failure(OSStatus(-1))
            }
        ) { [weak self] in
            self?.onSettingsChanged?()
        }
        window.contentView = NSHostingView(rootView: SettingsView(model: viewModel))
    }
    #endif

    private static func makeWindow(height: CGFloat) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Perch Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        return window
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

        permissionController.refreshStatus()

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

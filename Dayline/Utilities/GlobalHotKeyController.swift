import AppKit
import Carbon
import Foundation

struct TrayMenuHotKey {
    static let keyEquivalent = "k"
    static let carbonKeyCode = UInt32(kVK_ANSI_K)
    static let carbonModifierFlags = UInt32(cmdKey | controlKey)
    static let menuModifierFlags: NSEvent.ModifierFlags = [.command, .control]

    private static let meaningfulMenuModifierFlags: NSEvent.ModifierFlags = [.command, .control, .option, .shift]

    static func matchesMenuEvent(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown else {
            return false
        }

        let isExpectedKey = event.keyCode == UInt16(carbonKeyCode)
            || event.charactersIgnoringModifiers?.lowercased() == keyEquivalent
        guard isExpectedKey else {
            return false
        }

        return event.modifierFlags.intersection(meaningfulMenuModifierFlags) == menuModifierFlags
    }
}

final class GlobalHotKeyController {
    private let onToggle: @MainActor () -> Void
    private let hotKeyID = EventHotKeyID(
        signature: GlobalHotKeyController.fourCharacterCode("DYLN"),
        id: 1
    )
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    init(onToggle: @escaping @MainActor () -> Void) {
        self.onToggle = onToggle
        guard installEventHandler() else {
            return
        }

        registerHotKeyIfNeeded()
    }

    // The menu controller disables the global hotkey while the status menu is open.
    func setEnabled(_ isEnabled: Bool) {
        if isEnabled {
            registerHotKeyIfNeeded()
        } else {
            unregisterHotKeyIfNeeded()
        }
    }

    private func installEventHandler() -> Bool {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var receivedHotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &receivedHotKeyID
                )

                guard status == noErr else {
                    return status
                }

                let controller = Unmanaged<GlobalHotKeyController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                guard receivedHotKeyID.signature == controller.hotKeyID.signature,
                      receivedHotKeyID.id == controller.hotKeyID.id
                else {
                    return noErr
                }

                if Thread.isMainThread {
                    MainActor.assumeIsolated {
                        controller.onToggle()
                    }
                } else {
                    Task { @MainActor in
                        controller.onToggle()
                    }
                }

                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard handlerStatus == noErr else {
            DaylineLog.error("Failed to install global hotkey handler: \(handlerStatus)")
            return false
        }

        return true
    }

    private func registerHotKeyIfNeeded() {
        guard hotKeyRef == nil else {
            return
        }

        var hotKeyRef: EventHotKeyRef?
        let hotKeyStatus = RegisterEventHotKey(
            TrayMenuHotKey.carbonKeyCode,
            TrayMenuHotKey.carbonModifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard hotKeyStatus == noErr else {
            DaylineLog.error("Failed to register control-command-k hotkey: \(hotKeyStatus)")
            return
        }

        self.hotKeyRef = hotKeyRef
        DaylineLog.info("Registered global hotkey control-command-k")
    }

    private func unregisterHotKeyIfNeeded() {
        guard let hotKeyRef else {
            return
        }

        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
        DaylineLog.info("Unregistered global hotkey control-command-k")
    }

    private static func fourCharacterCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }

    deinit {
        unregisterHotKeyIfNeeded()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

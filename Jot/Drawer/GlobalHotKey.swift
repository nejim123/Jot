import Carbon.HIToolbox
import OSLog

/// A system-wide shortcut. Carbon's hot keys work in the sandbox and need no Accessibility permission.
final class GlobalHotKey {
    private static let signature: OSType = 0x4A4F_5421 // "JOT!"

    fileprivate let action: () -> Void
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?

    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action
        var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(
            GetApplicationEventTarget(), handleHotKey, 1, &pressed, Unmanaged.passUnretained(self).toOpaque(), &handler
        )
        let registered = RegisterEventHotKey(
            keyCode, modifiers, EventHotKeyID(signature: Self.signature, id: 1), GetApplicationEventTarget(), 0, &hotKey
        )
        guard installed == noErr, registered == noErr else {
            Logger.app.error("Couldn't register the global shortcut (install \(installed), register \(registered))")
            return nil
        }
    }

    isolated deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}

/// Carbon delivers hot keys on the main thread through the application event target.
nonisolated private func handleHotKey(_ call: EventHandlerCallRef?, _ event: EventRef?, _ context: UnsafeMutableRawPointer?) -> OSStatus {
    guard let context else { return OSStatus(eventNotHandledErr) }
    let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(context).takeUnretainedValue()
    MainActor.assumeIsolated { hotKey.action() }
    return noErr
}

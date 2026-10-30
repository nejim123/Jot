import AppKit
import Carbon.HIToolbox

/// The global shortcut that opens the drawer. Avoids ⌃⌥, which VoiceOver uses as its modifier,
/// and ⌥Space, which the ChatGPT app claims.
enum TasksShortcut {
    static let keyCode = UInt32(kVK_Space)
    static let carbonModifiers = UInt32(controlKey | shiftKey)
    static let keyEquivalent = " "
    static let modifierFlags: NSEvent.ModifierFlags = [.control, .shift]
    static let displayName = "⌃⇧Space"
}

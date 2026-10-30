import AppKit

/// Acts on the first click without handing the drawer the keyboard, so a peek stays a peek
/// and the app you were typing in keeps it.
final class PassiveButton: NSButton {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

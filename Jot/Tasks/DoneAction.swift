import AppKit

/// What the Done section offers. The menus read from here, so the shortcuts live in one place.
enum DoneAction {
    case toggleSection, clear

    func title(expanded: Bool) -> String {
        switch self {
        case .toggleSection: expanded ? String(localized: "Hide Done Tasks") : String(localized: "Show Done Tasks")
        case .clear: String(localized: "Clear Done Tasks")
        }
    }

    var selector: Selector {
        switch self {
        case .toggleSection: #selector(TasksViewController.toggleDoneSection(_:))
        case .clear: #selector(TasksViewController.clearDone(_:))
        }
    }

    func menuItem(target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title(expanded: false), action: selector, keyEquivalent: "")
        item.target = target
        switch self {
        case .toggleSection: item.keyEquivalent = "h"
        case .clear: item.keyEquivalent = "\u{8}"
        }
        item.keyEquivalentModifierMask = [.command, .shift]
        return item
    }
}

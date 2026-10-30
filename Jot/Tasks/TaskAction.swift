import AppKit

/// What a task offers. The menus, the context menu and VoiceOver all read from here.
enum TaskAction: CaseIterable {
    case toggle, progress, edit, copy, delete

    func title(done: Bool, inProgress: Bool = false) -> String {
        switch self {
        case .toggle: done ? String(localized: "Mark as Not Done") : String(localized: "Mark as Done")
        case .progress: inProgress ? String(localized: "Stop Working") : String(localized: "Start Working")
        case .edit: String(localized: "Edit Task")
        case .copy: String(localized: "Copy")
        case .delete: String(localized: "Delete")
        }
    }

    var selector: Selector {
        switch self {
        case .toggle: #selector(TasksViewController.toggleDone(_:))
        case .progress: #selector(TasksViewController.toggleProgress(_:))
        case .edit: #selector(TasksViewController.editTask(_:))
        case .copy: #selector(TasksViewController.copy(_:))
        case .delete: #selector(TasksViewController.delete(_:))
        }
    }

    /// Space and Return also work on a selected row; menus can't show plain keys without stealing them from text fields.
    func menuItem(target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title(done: false), action: selector, keyEquivalent: "")
        item.target = target
        switch self {
        case .toggle:
            item.keyEquivalent = "k"
        case .progress:
            item.keyEquivalent = "p"
        case .edit:
            break
        case .copy:
            item.keyEquivalent = "c"
        case .delete:
            item.keyEquivalent = "\u{8}"
            item.keyEquivalentModifierMask = []
        }
        return item
    }
}

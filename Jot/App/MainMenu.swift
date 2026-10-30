import AppKit

enum MainMenu {
    /// Jot lives in the menu bar, so this menu never shows. It still routes ⌘C, ⌘V, ⌘Z and the task shortcuts.
    static func make() -> NSMenu {
        NSMenu("", items: [app, file, edit, task].map { submenu in
            let item = NSMenuItem()
            item.submenu = submenu
            return item
        })
    }

    private static var app: NSMenu {
        NSMenu("Jot", items: [
            NSMenuItem(String(localized: "Quit Jot"), #selector(NSApplication.terminate(_:)), "q"),
        ])
    }

    private static var file: NSMenu {
        NSMenu(String(localized: "File"), items: [
            NSMenuItem(String(localized: "New Task"), #selector(AppDelegate.showTasks(_:)), "n"),
        ])
    }

    private static var edit: NSMenu {
        NSMenu(String(localized: "Edit"), items: [
            NSMenuItem(String(localized: "Undo"), Selector(("undo:")), "z"),
            NSMenuItem(String(localized: "Redo"), Selector(("redo:")), "z", [.command, .shift]),
            .separator(),
            NSMenuItem(String(localized: "Cut"), #selector(NSText.cut(_:)), "x"),
            NSMenuItem(String(localized: "Copy"), #selector(NSText.copy(_:)), "c"),
            NSMenuItem(String(localized: "Paste"), #selector(NSText.paste(_:)), "v"),
            TaskAction.delete.menuItem(),
            NSMenuItem(String(localized: "Select All"), #selector(NSText.selectAll(_:)), "a"),
        ])
    }

    private static var task: NSMenu {
        NSMenu(String(localized: "Task"), items: [
            TaskAction.toggle.menuItem(),
            TaskAction.progress.menuItem(),
            DoneAction.toggleSection.menuItem(),
            DoneAction.clear.menuItem(),
        ])
    }
}

private extension NSMenuItem {
    convenience init(_ title: String, _ action: Selector, _ key: String = "", _ modifiers: NSEvent.ModifierFlags = .command) {
        self.init(title: title, action: action, keyEquivalent: key)
        keyEquivalentModifierMask = modifiers
    }
}

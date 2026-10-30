import AppKit

enum StatusMenu {
    static func makeItem(showsShortcut: Bool) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: String(localized: "Jot"))

        let show = NSMenuItem(
            title: String(localized: "Show Tasks"),
            action: #selector(AppDelegate.showTasks(_:)),
            keyEquivalent: showsShortcut ? TasksShortcut.keyEquivalent : ""
        )
        show.keyEquivalentModifierMask = TasksShortcut.modifierFlags
        item.menu = NSMenu("", items: [
            show,
            .separator(),
            NSMenuItem(title: String(localized: "Open at Login"), action: #selector(AppDelegate.toggleOpenAtLogin(_:)), keyEquivalent: ""),
            .separator(),
            NSMenuItem(title: String(localized: "Quit Jot"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ])
        return item
    }
}

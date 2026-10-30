import AppIntents
import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = TaskStore(file: .standard)
    private lazy var drawer = TasksDrawer(store: store, shortcut: hotKey == nil ? nil : TasksShortcut.displayName)
    private var hotKey: GlobalHotKey?
    private var edgeTrigger: EdgeTrigger?
    private var statusItem: NSStatusItem?
    private var opensWhenActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .aqua)
        let store = store
        AppDependencyManager.shared.add(dependency: store)

        hotKey = GlobalHotKey(keyCode: TasksShortcut.keyCode, modifiers: TasksShortcut.carbonModifiers) { [weak self] in
            self?.drawer.toggle()
        }
        edgeTrigger = EdgeTrigger(zoneHeight: { [weak self] in self?.drawer.edgeZoneHeight(in: $0) ?? 0 }) { [weak self] screen in
            self?.drawer.peek(on: screen)
        }
        NSApp.mainMenu = MainMenu.make()
        statusItem = StatusMenu.makeItem(showsShortcut: hotKey != nil)
        // Opens only if the system lets Jot activate, as it does for a launch from Finder or Spotlight.
        // A login launch stays out of the way of whatever you're typing.
        opensWhenActive = true
        NSApp.activate()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard opensWhenActive else { return }
        opensWhenActive = false
        drawer.open()
    }

    // Opening Jot again from Finder or Spotlight shows the drawer.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        drawer.open()
        return false
    }
}

// MARK: - Menu actions

extension AppDelegate {
    @objc func showTasks(_ sender: Any?) {
        drawer.open()
    }

    @objc func toggleOpenAtLogin(_ sender: Any?) {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
            if service.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch {
            NSApp.presentError(error)
        }
    }
}

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleOpenAtLogin(_:)) {
            menuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
        return true
    }
}

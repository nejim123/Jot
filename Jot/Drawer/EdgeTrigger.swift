import AppKit

/// Fires when the pointer rests against the top of a screen's right edge.
final class EdgeTrigger {
    /// How long the pointer has to rest there, so passing scroll bars don't open the drawer.
    private static let dwell = Duration.milliseconds(200)

    /// Read on every move with a screen's visible frame, so the zone follows the drawer as it grows and shrinks.
    private let zoneHeight: (NSRect) -> CGFloat
    private let action: (NSScreen) -> Void
    private var monitors: [Any] = []
    private var pending: Task<Void, Never>?

    init(zoneHeight: @escaping (NSRect) -> CGFloat, action: @escaping (NSScreen) -> Void) {
        self.zoneHeight = zoneHeight
        self.action = action
        // Global covers other apps; local covers the pointer over Jot's own windows.
        monitors = [
            NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in self?.pointerMoved() },
            NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
                self?.pointerMoved()
                return event
            },
        ].compactMap { $0 }
    }

    isolated deinit {
        monitors.forEach(NSEvent.removeMonitor)
    }

    private func pointerMoved() {
        guard screen(at: NSEvent.mouseLocation) != nil else {
            pending?.cancel()
            pending = nil
            return
        }
        guard pending == nil else { return }
        pending = Task { [weak self] in
            try? await Task.sleep(for: Self.dwell)
            guard let self, !Task.isCancelled else { return }
            pending = nil
            if let screen = screen(at: NSEvent.mouseLocation) { action(screen) }
        }
    }

    private func screen(at point: NSPoint) -> NSScreen? {
        let screens = NSScreen.screens
        guard let index = Self.zoneIndex(for: point, in: screens.map { ($0.frame, $0.visibleFrame) }, zoneHeight: zoneHeight) else {
            return nil
        }
        return screens[index]
    }

    /// The screen whose top-right edge holds the point. An edge shared with a screen to the right doesn't count.
    /// Uses mouse rules (top edge in, bottom edge out), the same ones the drawer uses to stay open.
    nonisolated static func zoneIndex(for point: NSPoint, in screens: [(frame: NSRect, visible: NSRect)], zoneHeight: (NSRect) -> CGFloat) -> Int? {
        screens.firstIndex { screen in
            let bottom = screen.visible.maxY - zoneHeight(screen.visible)
            let zone = NSRect(x: screen.frame.maxX - 1, y: bottom, width: 1, height: screen.frame.maxY - bottom)
            let continuesRight = screens.contains { NSMouseInRect(NSPoint(x: point.x + 1, y: point.y), $0.frame, false) }
            return NSMouseInRect(point, zone, false) && !continuesRight
        }
    }
}

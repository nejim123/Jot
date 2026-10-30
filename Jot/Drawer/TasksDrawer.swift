import AppKit

/// A glass panel that floats above every app and slides in from the screen's right edge.
final class TasksDrawer: NSPanel {
    static let width: CGFloat = 360
    private static let maxHeight: CGFloat = 520
    private static let margin: CGFloat = 10

    private enum Motion {
        static let enter = (duration: 0.28, curve: CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1))
        static let exit = (duration: 0.2, curve: CAMediaTimingFunction(name: .easeIn))
        static let resize = (duration: 0.2, curve: CAMediaTimingFunction(name: .easeOut))
        /// How long the pointer can stray before a peek slides back.
        static let linger = Duration.milliseconds(400)
        static let poll = Duration.milliseconds(100)
    }

    private let tasks: TasksViewController
    private var isOpen = false
    /// Window frame animations don't cancel each other, so a resize waits for the slide to land.
    private var isSliding = false
    private var placement: (frame: NSRect, visible: NSRect) = (.zero, .zero)
    private var height = TasksDrawer.maxHeight
    private var pointerWatch: Task<Void, Never>?

    init(store: TaskStore, shortcut: String?) {
        tasks = TasksViewController(store: store, shortcut: shortcut)
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: Self.maxHeight),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true
        )
        title = String(localized: "Tasks")
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        // AppKit leaves key to sendEvent, so a passive button can act without taking it.
        becomesKeyOnlyIfNeeded = true
        // Stays reachable by shortcut and hover after a close hides the app.
        canHide = false
        isOpaque = false
        backgroundColor = .clear
        // The glass draws its own rounded edge; a window shadow would add a square one.
        hasShadow = false
        isReleasedWhenClosed = false
        // Hooked up first: loading the view renders the list and reports its height.
        tasks.onFittingHeightChange = { [weak self] in self?.fit(height: $0) }
        contentViewController = tasks
    }

    override var canBecomeKey: Bool { true }

    /// The edge zone that peeks the drawer on a screen, as tall as the drawer there so a resting pointer keeps it open.
    func edgeZoneHeight(in visible: NSRect) -> CGFloat {
        shownHeight(in: visible) + Self.margin
    }

    /// Slides out without taking the keyboard, and slides back once the pointer moves away.
    func peek(on screen: NSScreen) {
        // A drawer that has the keyboard, even one still closing, ignores the edge.
        guard !isKeyWindow else { return }
        if isOpen, placement.frame != screen.frame {
            isOpen = false
            orderOut(nil)
        }
        slideOut(on: screen)
        followPointer()
    }

    /// Slides out with the cursor in the add field.
    func open() {
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main else { return }
        slideOut(on: screen)
        makeKeyAndOrderFront(nil)
        tasks.beginCapture()
    }

    func toggle() {
        isOpen && isKeyWindow ? dismiss() : open()
    }

    func dismiss() {
        guard isOpen else { return }
        isOpen = false
        pointerWatch?.cancel()
        // Ends editing, so the add field's focus ring doesn't show in a later peek. A draft stays in the field.
        makeFirstResponder(nil)
        let hidden = frames().hidden
        animate(Motion.exit) { [self] in
            if reduceMotion {
                animator().alphaValue = 0
            } else {
                animator().setFrame(hidden, display: true)
            }
        } completion: { [weak self] in
            guard let self, !isOpen else { return }
            orderOut(nil)
            // Opened from Finder or Spotlight, Jot is the active app; hiding hands the keyboard back.
            // An alert that took the keyboard keeps Jot showing.
            if NSApp.isActive, NSApp.keyWindow == nil { NSApp.hide(nil) }
        }
    }

    override func cancelOperation(_ sender: Any?) {
        dismiss()
    }

    // A click into a peek hands it the keyboard, so from then on Escape or a click elsewhere closes it.
    // A passive button, like copy, acts without it: the peek still closes on its own and ⌘V reaches your app.
    override func sendEvent(_ event: NSEvent) {
        if !isKeyWindow, [.leftMouseDown, .rightMouseDown].contains(event.type),
           !(contentView?.hitTest(event.locationInWindow) is PassiveButton) {
            makeKey()
        }
        super.sendEvent(event)
    }

    override func becomeKey() {
        super.becomeKey()
        tasks.showKeyboardHints(true)
    }

    // Clicking another app closes, like Spotlight.
    override func resignKey() {
        super.resignKey()
        dismiss()
    }

    private func slideOut(on screen: NSScreen) {
        guard !isOpen else { return }
        isOpen = true
        tasks.prepareToShow()
        // Reopened while still closing, the panel is already key and won't get becomeKey again.
        tasks.showKeyboardHints(isKeyWindow)
        placement = (screen.frame, screen.visibleFrame)
        let (shown, hidden) = frames()
        if !isVisible {
            setFrame(reduceMotion ? shown : hidden, display: false)
            alphaValue = reduceMotion ? 0 : 1
        }
        orderFrontRegardless()
        isSliding = true
        animate(Motion.enter) { [self] in
            if reduceMotion {
                animator().alphaValue = 1
            } else {
                animator().setFrame(shown, display: true)
            }
        } completion: { [weak self] in
            guard let self else { return }
            isSliding = false
            if isOpen, frame != frames().shown { resize() }
        }
    }

    /// Hugs the list, up to a height that leaves the screen readable.
    private func fit(height fitting: CGFloat) {
        let height = min(fitting, Self.maxHeight)
        guard height != self.height else { return }
        self.height = height
        guard isOpen, !isSliding else { return }
        resize()
    }

    private func resize() {
        let shown = frames().shown
        animate(reduceMotion ? (0, Motion.resize.curve) : Motion.resize) { [self] in
            animator().setFrame(shown, display: true)
        }
    }

    /// Stays while the pointer is over the drawer or the corner it came from. Clicking in hands control to
    /// the keyboard rules: Escape or a click elsewhere.
    private func followPointer() {
        pointerWatch?.cancel()
        pointerWatch = Task { [weak self] in
            var strayedAt: ContinuousClock.Instant?
            while let self, !Task.isCancelled, isOpen, !isKeyWindow {
                if NSMouseInRect(NSEvent.mouseLocation, hoverRegion, false) {
                    strayedAt = nil
                } else if let strayedAt, ContinuousClock.now - strayedAt >= Motion.linger {
                    dismiss()
                    return
                } else if strayedAt == nil {
                    strayedAt = .now
                }
                try? await Task.sleep(for: Motion.poll)
            }
        }
    }

    /// The drawer plus the strip between it and the screen's top-right corner. Holds the whole edge zone.
    private var hoverRegion: NSRect {
        let shown = frames().shown
        return NSRect(x: shown.minX, y: shown.minY, width: placement.frame.maxX - shown.minX, height: placement.frame.maxY - shown.minY)
    }

    /// Shown hugs the top-right corner below the menu bar; hidden sits just past the screen's right edge.
    private func frames() -> (shown: NSRect, hidden: NSRect) {
        let height = shownHeight(in: placement.visible)
        let y = placement.visible.maxY - height - Self.margin
        return (
            NSRect(x: placement.visible.maxX - Self.width - Self.margin, y: y, width: Self.width, height: height),
            NSRect(x: placement.frame.maxX, y: y, width: Self.width, height: height)
        )
    }

    /// The fitted height, clamped so a short screen keeps a margin above and below.
    private func shownHeight(in visible: NSRect) -> CGFloat {
        min(height, visible.height - Self.margin * 2)
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private func animate(
        _ motion: (duration: Double, curve: CAMediaTimingFunction),
        _ changes: () -> Void,
        completion: @escaping @MainActor @Sendable () -> Void = {}
    ) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = motion.duration
            context.timingFunction = motion.curve
            changes()
        }, completionHandler: { MainActor.assumeIsolated { completion() } })
    }
}

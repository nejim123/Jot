import AppKit

/// Space marks the selection done and Return renames it, as in Finder and Reminders.
final class TaskTableView: NSTableView {
    var onToggle: (() -> Void)?
    var onEdit: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        guard event.modifierFlags.isDisjoint(with: [.command, .option, .control, .shift]) else {
            return super.keyDown(with: event)
        }
        switch event.specialKey {
        case .carriageReturn?, .enter?:
            onEdit?()
        default:
            event.charactersIgnoringModifiers == " " ? onToggle?() : super.keyDown(with: event)
        }
    }
}

/// Highlights under the pointer and shows the task's hover buttons there.
final class TaskRowView: NSTableRowView {
    private var isHovered = false {
        didSet {
            needsDisplay = true
            taskCell?.showsCopyButton(isHovered)
        }
    }

    private var taskCell: TaskCellView? {
        view(atColumn: 0) as? TaskCellView
    }

    // A cell swapped in by a reload picks up the hover it lands under.
    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        (subview as? TaskCellView)?.showsCopyButton(isHovered)
    }

    // Added once: an area rebuilt under the pointer never reports the exit, so a row that moves away would stay hovered.
    init() {
        super.init(frame: .zero)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)
        guard isHovered, !isSelected, taskCell != nil else { return }
        NSColor.quaternarySystemFill.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: Style.rowInset, dy: 0), xRadius: Style.rowRadius, yRadius: Style.rowRadius).fill()
    }
}

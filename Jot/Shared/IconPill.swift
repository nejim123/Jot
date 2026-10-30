import AppKit

/// A light pill holding one icon button, like a task's copy button.
final class IconPill: CapsuleView {
    /// The pill stays light on a selected row, so its icon keeps normal colors whatever style the row hands down.
    private final class Cell: NSButtonCell {
        override var backgroundStyle: NSView.BackgroundStyle {
            get { .normal }
            set {}
        }
    }

    let button = PassiveButton()

    init() {
        super.init(frame: .zero)
        button.cell = Cell()
        fillColor = .controlBackgroundColor
        borderColor = .separatorColor
        borderWidth = 1

        button.isBordered = false
        button.imagePosition = .imageOnly
        button.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        button.contentTintColor = .secondaryLabelColor
        // Its action is also one of the task's VoiceOver actions, so the task stays a single stop.
        // The cell is what VoiceOver sees, not the button.
        button.cell?.setAccessibilityElement(false)
        addSubview(button)
        button.pinEdges(to: self)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Style.iconPillSize.width),
            heightAnchor.constraint(equalToConstant: Style.iconPillSize.height),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(_ symbol: String, tint: NSColor = .secondaryLabelColor) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.contentTintColor = tint
    }
}

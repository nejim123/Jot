import AppKit

/// "Done" with its count, a disclosure to show or hide the finished tasks, and Clear.
final class DoneHeaderView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("DoneHeader")

    let disclosure = NSButton(title: String(localized: "Done"), target: nil, action: nil)
    let clearButton = NSButton(title: String(localized: "Clear"), target: nil, action: nil)
    private let count = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier

        disclosure.setButtonType(.toggle)
        disclosure.image = Self.chevron("chevron.right")
        disclosure.alternateImage = Self.chevron("chevron.down")
        disclosure.alternateTitle = disclosure.title
        disclosure.isBordered = false
        disclosure.font = Style.Font.section
        disclosure.contentTintColor = .secondaryLabelColor
        disclosure.imagePosition = .imageTrailing
        disclosure.imageHugsTitle = true
        disclosure.setAccessibilityRole(.disclosureTriangle)
        disclosure.setAccessibilityLabel(String(localized: "Done tasks"))

        count.font = Style.Font.count
        count.textColor = .secondaryLabelColor

        clearButton.isBordered = false
        clearButton.font = Style.Font.subtitle
        clearButton.contentTintColor = .controlAccentColor
        clearButton.setAccessibilityLabel(String(localized: "Clear done tasks"))

        for button in [disclosure, clearButton] {
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: Style.minimumHitHeight).isActive = true
        }

        let row = NSStackView(views: [disclosure, count, NSView(), clearButton])
        row.distribution = .fill
        row.spacing = 6
        addSubview(row)
        // More space above than below, so the heading belongs to the tasks it introduces.
        // A stack's own insets across its axis give way when the table sizes the row.
        row.pinEdges(to: self, insets: NSEdgeInsets(top: 10, left: 0, bottom: 4, right: 0))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(count done: Int, expanded: Bool) {
        disclosure.state = expanded ? .on : .off
        count.stringValue = done.formatted()
        count.setAccessibilityLabel(String(AttributedString(localized: "^[\(done) task](inflect: true)").characters))
    }

    private static func chevron(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 10, weight: .bold))
    }
}

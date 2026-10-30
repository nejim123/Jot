import AppKit

/// A soft capsule around the add field. An accent ring marks keyboard focus.
final class AddTaskField: CapsuleView {
    let field = SubmitField()

    init() {
        super.init(frame: .zero)
        fillColor = .quaternaryLabelColor
        borderWidth = 1.5

        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "plus.circle.fill", accessibilityDescription: nil)
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        icon.contentTintColor = .controlAccentColor
        icon.cell?.setAccessibilityElement(false)

        field.font = Style.Font.field
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.onFocusChange = { [weak self] focused in
            self?.borderColor = focused ? .controlAccentColor : .clear
        }

        let row = NSStackView(views: [icon, field])
        row.spacing = 6
        // The icon sits concentric with the capsule's rounded end, and the text lines up with task titles.
        row.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 12)
        addSubview(row)
        row.pinEdges(to: self)
    }
}

import AppKit

/// A tinted capsule holding a number. Sized by its number, so it never stretches in a stack.
final class CountBadge: CapsuleView {
    private static let padding = NSSize(width: 8, height: 2)
    private let label = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        fillColor = NSColor.controlAccentColor.withAlphaComponent(0.18)
        label.font = Style.Font.count
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        for orientation in [NSLayoutConstraint.Orientation.horizontal, .vertical] {
            setContentHuggingPriority(.required, for: orientation)
            setContentCompressionResistancePriority(.required, for: orientation)
        }
    }

    override var intrinsicContentSize: NSSize {
        let text = label.intrinsicContentSize
        return NSSize(width: text.width + Self.padding.width * 2, height: text.height + Self.padding.height * 2)
    }

    func show(_ count: Int, accessibilityLabel: String) {
        isHidden = count == 0
        label.stringValue = count.formatted()
        label.setAccessibilityLabel(accessibilityLabel)
        invalidateIntrinsicContentSize()
    }
}

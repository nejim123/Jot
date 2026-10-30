import AppKit

final class EmptyStateView: NSStackView {
    init() {
        let image = NSImageView()
        image.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
        image.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 34, weight: .light)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: .controlAccentColor))
        image.cell?.setAccessibilityElement(false)

        let title = NSTextField(labelWithString: String(localized: "All clear"))
        title.font = Style.Font.emptyTitle

        let hint = NSTextField(wrappingLabelWithString: String(localized: "Add a task above and press Return."))
        hint.alignment = .center
        hint.textColor = .secondaryLabelColor

        super.init(frame: .zero)
        orientation = .vertical
        spacing = 6
        setViews([image, title, hint], in: .center)
        setCustomSpacing(10, after: image)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

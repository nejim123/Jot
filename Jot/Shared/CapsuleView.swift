import AppKit

/// A pill drawn with layers, so its fill shows inside glass and follows the appearance.
class CapsuleView: NSView {
    var fillColor: NSColor = .clear {
        didSet { needsDisplay = true }
    }
    var borderColor: NSColor = .clear {
        didSet { needsDisplay = true }
    }
    var borderWidth: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var wantsUpdateLayer: Bool { true }

    // Runs inside the view's appearance, so dynamic colors resolve for Increase Contrast and accent changes.
    override func updateLayer() {
        guard let layer else { return }
        layer.cornerRadius = bounds.height / 2
        layer.cornerCurve = .continuous
        layer.backgroundColor = fillColor.cgColor
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }

    override func layout() {
        super.layout()
        needsDisplay = true
    }
}

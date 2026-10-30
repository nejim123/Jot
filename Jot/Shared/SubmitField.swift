import AppKit

/// A text field where Return turns the text into a task and clears it.
final class SubmitField: NSTextField {
    /// Returns true when the text became a task.
    var onSubmit: ((String) -> Bool)?
    var onFocusChange: ((Bool) -> Void)?

    init() {
        super.init(frame: .zero)
        placeholderString = String(localized: "Add a task")
        setAccessibilityLabel(String(localized: "New task"))
        usesSingleLineMode = true
        lineBreakMode = .byTruncatingTail
        cell?.isScrollable = true
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func becomeFirstResponder() -> Bool {
        let focused = super.becomeFirstResponder()
        if focused { onFocusChange?(true) }
        return focused
    }

    // Typing happens in the window's field editor, so focus leaving shows up as editing ending.
    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        onFocusChange?(false)
    }
}

extension SubmitField: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            if onSubmit?(stringValue) == true { stringValue = "" }
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            // Hand Escape to the window so a panel can close; the draft stays.
            window?.cancelOperation(nil)
            return true
        default:
            return false
        }
    }
}

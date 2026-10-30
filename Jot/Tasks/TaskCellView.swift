import AppKit

final class TaskCellView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("TaskCell")
    /// How long the copy button shows its check after a click.
    private static let copiedFeedback = Duration.milliseconds(1200)

    var onToggle: (() -> Void)?
    var onProgress: (() -> Void)?
    var onRename: ((String) -> Void)?
    var onCopy: (() -> Void)?

    private let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let title = NSTextField(wrappingLabelWithString: "")
    private let startPill = IconPill()
    private let copyPill = IconPill()
    private let hoverPills = NSStackView()
    private var task: TaskItem?
    private var copiedReset: Task<Void, Never>?
    private var isHovered = false

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier

        checkbox.alternateImage = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
        checkbox.imagePosition = .imageOnly
        checkbox.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        checkbox.target = self
        checkbox.action = #selector(toggle)
        checkbox.setContentHuggingPriority(.required, for: .horizontal)

        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // A selectable title would take focus from the table on a second click.
        title.isSelectable = false
        title.delegate = self
        // The checkbox carries the title and the task's actions for VoiceOver, so the row reads once.
        title.cell?.setAccessibilityElement(false)
        textField = title

        startPill.button.target = self
        startPill.button.action = #selector(toggleProgress)
        copyPill.button.toolTip = String(localized: "Copy")
        copyPill.button.target = self
        copyPill.button.action = #selector(copyTitle)
        resetCopyButton()

        let row = NSStackView(views: [checkbox, title])
        row.distribution = .fill
        row.alignment = .firstBaseline
        row.spacing = 10
        row.edgeInsets = NSEdgeInsets(top: 7, left: 2, bottom: 7, right: 4)
        addSubview(row)
        row.pinEdges(to: self)

        // Float over the end of the first line on hover, so titles keep their full width.
        hoverPills.setViews([startPill, copyPill], in: .leading)
        hoverPills.spacing = 4
        hoverPills.isHidden = true
        addSubview(hoverPills)
        hoverPills.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hoverPills.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            hoverPills.centerYAnchor.constraint(equalTo: checkbox.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(with task: TaskItem, actions: [NSAccessibilityCustomAction]) {
        self.task = task
        checkbox.state = task.isDone ? .on : .off
        checkbox.image = NSImage(systemSymbolName: task.isInProgress ? "circle.lefthalf.filled" : "circle", accessibilityDescription: nil)
        checkbox.contentTintColor = task.isDone || task.isInProgress ? .controlAccentColor : .secondaryLabelColor
        checkbox.setAccessibilityLabel(task.isInProgress ? String(localized: "\(task.title), in progress") : task.title)
        startPill.isHidden = task.isDone
        startPill.show(task.isInProgress ? "stop.fill" : "play.fill")
        startPill.button.toolTip = TaskAction.progress.title(done: false, inProgress: task.isInProgress)
        checkbox.cell?.setAccessibilityCustomActions(actions)
        showTitle(of: task)
        copiedReset?.cancel()
        resetCopyButton()
    }

    /// Shown while the pointer is over the row.
    func showsCopyButton(_ shown: Bool) {
        isHovered = shown
        updateCopyPill()
    }

    private func showTitle(of task: TaskItem) {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: Style.Font.task,
            .foregroundColor: task.isDone ? NSColor.secondaryLabelColor : NSColor.labelColor,
        ]
        if task.isDone { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
        title.attributedStringValue = NSAttributedString(string: task.title, attributes: attributes)
    }

    /// Editable only while renaming, because an editable field stops reporting its wrapped height to the row.
    /// Turning selectable off afterwards turns editing off too.
    func beginEditing() {
        title.isEditable = true
        updateCopyPill()
    }

    @objc private func toggle() {
        onToggle?()
    }

    @objc private func toggleProgress() {
        onProgress?()
    }

    @objc private func copyTitle() {
        onCopy?()
        copyPill.show("checkmark", tint: .controlAccentColor)
        copiedReset?.cancel()
        copiedReset = Task { [weak self] in
            try? await Task.sleep(for: Self.copiedFeedback)
            guard !Task.isCancelled else { return }
            self?.resetCopyButton()
        }
    }

    /// Hidden during a rename, where it would cover the text. VoiceOver sees the title only then, as the field being edited.
    private func updateCopyPill() {
        hoverPills.isHidden = !isHovered || title.isEditable
        title.cell?.setAccessibilityElement(title.isEditable)
    }

    private func resetCopyButton() {
        copyPill.show("doc.on.doc")
    }
}

extension TaskCellView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ notification: Notification) {
        title.isSelectable = false
        updateCopyPill()
        guard var task else { return }
        // Restyled either way: the field editor leaves plain text, and an unchanged title doesn't re-render.
        if let edited = title.stringValue.taskTitle {
            task.title = edited
            onRename?(edited)
        }
        showTitle(of: task)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        guard selector == #selector(NSResponder.cancelOperation(_:)), let task else { return false }
        title.abortEditing()
        title.isSelectable = false
        updateCopyPill()
        showTitle(of: task)
        window?.makeFirstResponder(enclosingScrollView?.documentView)
        return true
    }
}

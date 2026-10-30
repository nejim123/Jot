import AppKit

/// "Tasks", today's date and how many are left.
final class TasksHeaderView: NSView {
    private let date = NSTextField(labelWithString: "")
    private let badge = CountBadge()

    init() {
        super.init(frame: .zero)
        let title = NSTextField(labelWithString: String(localized: "Tasks"))
        title.font = Style.Font.title
        date.font = Style.Font.subtitle
        date.textColor = .secondaryLabelColor

        let titles = NSStackView(views: [title, date])
        titles.orientation = .vertical
        titles.alignment = .leading
        titles.spacing = 1

        let row = NSStackView(views: [titles, badge])
        row.distribution = .fill
        row.alignment = .centerY
        titles.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addSubview(row)
        row.pinEdges(to: self)
        refreshDate()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func refreshDate() {
        date.stringValue = Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    func show(openCount: Int) {
        badge.show(openCount, accessibilityLabel: String(AttributedString(localized: "^[\(openCount) task](inflect: true) to do").characters))
    }
}

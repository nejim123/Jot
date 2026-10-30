import AppKit

final class TasksViewController: NSViewController {
    nonisolated fileprivate enum Section { case tasks }
    nonisolated fileprivate enum Row: Hashable { case task(TaskItem.ID), doneHeader }

    /// How long a checked task stays put, so you see the check before it moves to Done.
    private static let linger = Duration.milliseconds(600)
    private static let showsDoneKey = "showsDoneTasks"

    /// Vertical gaps, shared by the constraints and the fitting height.
    private enum Gap {
        static let headerToField: CGFloat = 12
        static let fieldToList: CGFloat = 6
        static let listToFooter: CGFloat = 4
        static let bottom: CGFloat = 12
    }

    private let store: TaskStore
    private let shortcut: String?
    private let tableView = TaskTableView()
    private let addField = AddTaskField()
    private let header = TasksHeaderView()
    private let emptyState = EmptyStateView()
    private let scrollView = NSScrollView()
    private let footer = NSStackView()
    private lazy var escapeHint = hint(String(localized: "Esc closes"))

    /// Reports the height that shows every row, so the drawer can hug the list.
    var onFittingHeightChange: ((CGFloat) -> Void)?
    private lazy var dataSource = makeDataSource()
    private var tasksByID: [TaskItem.ID: TaskItem] = [:]
    private var doneCount = 0
    private var lingering: Set<TaskItem.ID> = []
    private var pendingReveal: TaskItem.ID?
    private var pendingSelection: PendingSelection?

    /// What to select once the next render lands, so ⌫ and Space can repeat.
    private enum PendingSelection {
        /// Where removed tasks were, or the row above.
        case slot(Int)
        /// Tasks that moved, wherever they land.
        case tasks(Set<TaskItem.ID>)
    }

    private var showsDone: Bool {
        get { UserDefaults.standard.bool(forKey: Self.showsDoneKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.showsDoneKey) }
    }

    init(store: TaskStore, shortcut: String?) {
        self.store = store
        self.shortcut = shortcut
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let column = NSTableColumn(identifier: TaskCellView.identifier)
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.headerView = nil
        tableView.style = .inset
        tableView.rowSizeStyle = .custom
        tableView.usesAutomaticRowHeights = true
        // The estimate for rows not laid out yet: one line of task text.
        tableView.rowHeight = 31
        tableView.allowsMultipleSelection = true
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(editTask(_:))
        tableView.menu = NSMenu("", items: [
            TaskAction.toggle.menuItem(target: self),
            TaskAction.progress.menuItem(target: self),
            TaskAction.edit.menuItem(target: self),
            TaskAction.copy.menuItem(target: self),
            .separator(),
            TaskAction.delete.menuItem(target: self),
            .separator(),
            DoneAction.toggleSection.menuItem(target: self),
            DoneAction.clear.menuItem(target: self),
        ])
        tableView.setAccessibilityLabel(String(localized: "Tasks"))
        tableView.onToggle = { [weak self] in self?.toggleDone(nil) }
        tableView.onEdit = { [weak self] in self?.editTask(nil) }
        addField.field.onSubmit = { [weak self] in self?.add($0) ?? false }

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        footer.setViews([hint(shortcut.map { String(localized: "\($0) opens Jot") } ?? ""), NSView(), escapeHint], in: .leading)
        footer.distribution = .fill

        let container = NSView()
        for subview in [header, addField, scrollView, emptyState, footer] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(subview)
        }
        let padding = Style.padding
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding + 4),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding - 2),

            addField.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Gap.headerToField),
            addField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            addField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),

            scrollView.topAnchor.constraint(equalTo: addField.bottomAnchor, constant: Gap.fieldToList),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            footer.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: Gap.listToFooter),

            footer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding + 4),
            footer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding - 4),
            footer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Gap.bottom),

            emptyState.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            emptyState.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            emptyState.widthAnchor.constraint(lessThanOrEqualTo: scrollView.widthAnchor, multiplier: 0.8),
        ])

        let glass = NSGlassEffectView()
        glass.cornerRadius = Style.cornerRadius
        glass.contentView = container
        container.pinEdges(to: glass)
        view = glass
    }

    private func hint(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = Style.Font.hint
        label.textColor = .secondaryLabelColor
        return label
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Rows measure their real height only once laid out, so re-report as the table grows.
        tableView.postsFrameChangedNotifications = true
        _ = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: tableView, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reportFittingHeight() }
        }
        observeStore()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        tableView.sizeLastColumnToFit()
        reportFittingHeight()
    }

    func beginCapture() {
        view.window?.makeFirstResponder(addField.field)
    }

    func prepareToShow() {
        header.refreshDate()
    }

    /// Escape only reaches Jot once the drawer has the keyboard.
    func showKeyboardHints(_ shown: Bool) {
        escapeHint.isHidden = !shown
    }

    /// Renders now, then again on the next main-actor turn after any change to the tasks.
    /// Renders outside the tracking, so a rename the render commits still schedules the next one.
    private func observeStore() {
        let (open, done) = withObservationTracking {
            (store.openTasks, store.doneTasks)
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeStore() }
        }
        render(open: open, done: done)
    }
}

// MARK: - Rendering

private extension TasksViewController {
    func render(open: [TaskItem], done: [TaskItem]) {
        let tasks = open + done
        let changed = tasks.filter { task in tasksByID[task.id].map { $0 != task } ?? false }
        tasksByID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        // A task checked a moment ago keeps its place until it lingers out.
        let shownOpen = (open + done.filter { lingering.contains($0.id) }).sorted(using: TaskItem.listOrder)
        let shownDone = done.filter { !lingering.contains($0.id) }
        doneCount = shownDone.count

        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections([.tasks])
        snapshot.appendItems(shownOpen.map { .task($0.id) })
        if !shownDone.isEmpty {
            // Updated in place, so the disclosure keeps keyboard focus. A new header is configured by the data source.
            if let row = dataSource.row(forItemIdentifier: .doneHeader), row >= 0,
               let header = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? DoneHeaderView {
                header.configure(count: doneCount, expanded: showsDone)
            }
            snapshot.appendItems([.doneHeader])
            if showsDone { snapshot.appendItems(shownDone.map { .task($0.id) }) }
        }

        // Always diff, since the non-animated path is reloadData, which drops the selection and a rename in progress.
        let animates = view.window?.isVisible == true && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        dataSource.defaultRowAnimation = animates ? .effectFade : []
        NSAnimationContext.runAnimationGroup { context in
            if !animates { context.duration = 0 }
            // Moves land first: reloading a row in the same pass as a move can fill it with another task.
            dataSource.apply(snapshot, animatingDifferences: true)
            snapshot.reloadItems(changed.map { .task($0.id) }.filter(snapshot.itemIdentifiers.contains))
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                self?.reportFittingHeight()
                self?.restoreFocus()
            }
        }
        emptyState.isHidden = !tasks.isEmpty
        header.show(openCount: open.count)
    }

    func rerender() {
        render(open: store.openTasks, done: store.doneTasks)
    }

    func reportFittingHeight() {
        let rows = tableView.numberOfRows
        let list = rows == 0
            ? emptyState.fittingSize.height + Style.padding * 4
            : tableView.rect(ofRow: rows - 1).maxY + tableView.rect(ofRow: 0).minY
        let chrome = Style.padding + header.fittingSize.height + Gap.headerToField + addField.fittingSize.height
            + Gap.fieldToList + Gap.listToFooter + footer.fittingSize.height + Gap.bottom
        onFittingHeightChange?(chrome + list)
    }

    /// Scrolls to a task just added, and puts back a selection the render would have dropped, in view.
    func restoreFocus() {
        if let id = pendingReveal, let row = dataSource.row(forItemIdentifier: .task(id)), row >= 0 {
            tableView.scrollRowToVisible(row)
        }
        switch pendingSelection {
        case .slot(let row)?:
            if let next = [row, row - 1].first(where: { task(atRow: $0) != nil }) {
                tableView.selectRowIndexes([next], byExtendingSelection: false)
            }
        case .tasks(let ids)?:
            let rows = ids.compactMap { dataSource.row(forItemIdentifier: .task($0)) }.filter { $0 >= 0 }
            tableView.selectRowIndexes(IndexSet(rows), byExtendingSelection: false)
            if let first = rows.min() { tableView.scrollRowToVisible(first) }
        case nil:
            break
        }
        pendingReveal = nil
        pendingSelection = nil
    }

    func makeDataSource() -> NSTableViewDiffableDataSource<Section, Row> {
        let source = NSTableViewDiffableDataSource<Section, Row>(tableView: tableView) { [weak self] tableView, _, _, row in
            guard let self else { return NSView() }
            switch row {
            case .doneHeader:
                let header = tableView.makeView(withIdentifier: DoneHeaderView.identifier, owner: nil) as? DoneHeaderView ?? DoneHeaderView()
                header.configure(count: doneCount, expanded: showsDone)
                header.disclosure.target = self
                header.disclosure.action = #selector(toggleDoneSection(_:))
                header.clearButton.target = self
                header.clearButton.action = #selector(clearDone(_:))
                return header
            case .task(let id):
                let cell = tableView.makeView(withIdentifier: TaskCellView.identifier, owner: nil) as? TaskCellView ?? TaskCellView()
                guard let task = tasksByID[id] else { return cell }
                cell.configure(with: task, actions: accessibilityActions(for: task))
                cell.onToggle = { [weak self] in self?.perform(.toggle, on: [id]) }
                cell.onProgress = { [weak self] in self?.perform(.progress, on: [id]) }
                cell.onRename = { [weak self] in self?.store.rename(id, to: $0) }
                cell.onCopy = { [weak self] in self?.perform(.copy, on: [id]) }
                return cell
            }
        }
        // The diffable source asks this, not the delegate, for row views.
        source.rowViewProvider = { _, _, _ in TaskRowView() }
        return source
    }

    func accessibilityActions(for task: TaskItem) -> [NSAccessibilityCustomAction] {
        TaskAction.allCases.filter { $0 != .progress || !task.isDone }.map { action in
            NSAccessibilityCustomAction(name: action.title(done: task.isDone, inProgress: task.isInProgress)) { [weak self] in
                self?.perform(action, on: [task.id])
                return true
            }
        }
    }

    func task(atRow row: Int) -> TaskItem? {
        guard row >= 0, row < tableView.numberOfRows, case .task(let id) = dataSource.itemIdentifier(forRow: row) else { return nil }
        return tasksByID[id]
    }

    /// The right-clicked row when it sits outside the selection, otherwise the selection.
    var targetIDs: [TaskItem.ID] {
        let clicked = tableView.clickedRow
        let rows = clicked >= 0 && !tableView.selectedRowIndexes.contains(clicked) ? IndexSet(integer: clicked) : tableView.selectedRowIndexes
        return rows.compactMap { task(atRow: $0)?.id }
    }
}

// MARK: - Actions

extension TasksViewController {
    @objc func toggleDone(_ sender: Any?) {
        perform(.toggle, on: targetIDs)
    }

    @objc func toggleProgress(_ sender: Any?) {
        perform(.progress, on: targetIDs)
    }

    @objc func editTask(_ sender: Any?) {
        perform(.edit, on: targetIDs)
    }

    @objc func copy(_ sender: Any?) {
        perform(.copy, on: targetIDs)
    }

    @objc func delete(_ sender: Any?) {
        perform(.delete, on: targetIDs)
    }

    @objc func clearDone(_ sender: Any?) {
        delete(store.doneTasks)
    }

    @objc func toggleDoneSection(_ sender: Any?) {
        showsDone.toggle()
        rerender()
    }

    private func perform(_ action: TaskAction, on ids: [TaskItem.ID]) {
        // A change reloads rows, so focus inside one moves to the table first, and a rename in progress lands.
        if ![.edit, .copy].contains(action), (view.window?.firstResponder as? NSView)?.isDescendant(of: tableView) == true {
            view.window?.makeFirstResponder(tableView)
        }
        // Read from the store, since a rename that just landed hasn't rendered yet.
        let tasks = ids.compactMap { id in store.tasks.first { $0.id == id } }
        guard !tasks.isEmpty else { return }
        switch action {
        case .toggle:
            // A mixed selection all becomes done; an all-done selection reopens.
            let markDone = tasks.contains { !$0.isDone }
            let changing = tasks.filter { $0.isDone != markDone }
            let ids = Set(changing.map(\.id))
            if markDone {
                lingering.formUnion(ids)
                Task { [weak self] in
                    try? await Task.sleep(for: Self.linger)
                    self?.lingerOut(ids)
                }
            } else {
                lingering.subtract(ids)
                keepSelection(on: ids)
            }
            ids.forEach { store.setDone(markDone, for: $0) }
            registerToggleUndo(action, restoring: changing, named: action.title(done: !markDone))
            announceDone(markDone)
        case .progress:
            // A mixed selection all starts; an all-started selection stops. Done tasks stay as they are.
            let open = tasks.filter { !$0.isDone }
            let start = open.contains { !$0.isInProgress }
            let changing = open.filter { $0.isInProgress != start }
            guard !changing.isEmpty else { return }
            keepSelection(on: Set(tasks.map(\.id)))
            store.setStarted(start, for: Set(changing.map(\.id)))
            registerToggleUndo(action, restoring: changing, named: action.title(done: false, inProgress: !start))
            announceStarted(start)
        case .edit:
            guard let row = dataSource.row(forItemIdentifier: .task(tasks[0].id)), row >= 0 else { return }
            tableView.scrollRowToVisible(row)
            guard let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: true) as? TaskCellView else { return }
            view.window?.makeKey()
            tableView.selectRowIndexes([row], byExtendingSelection: false)
            cell.beginEditing()
            tableView.editColumn(0, row: row, with: nil, select: true)
        case .copy:
            // One task per line, in list order, so a paste reads like the list.
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(tasks.map(\.title).joined(separator: "\n"), forType: .string)
            VoiceOver.announce(String(localized: "Copied"))
        case .delete:
            if selectionIsWithin(Set(tasks.map(\.id))), let row = tableView.selectedRowIndexes.first {
                pendingSelection = .slot(row)
            }
            delete(tasks)
        }
    }

    /// Undo puts back the exact dates, so a task returns to its old place.
    private func registerToggleUndo(_ action: TaskAction, restoring saved: [TaskItem], named name: String) {
        undoManager?.registerUndo(withTarget: self) { controller in
            let ids = Set(saved.map(\.id))
            let current = controller.store.tasks.filter { ids.contains($0.id) }
            controller.lingering.subtract(ids)
            controller.keepSelection(on: ids)
            controller.store.restoreCompletion(of: saved)
            controller.registerToggleUndo(action, restoring: current, named: name)
            if action == .progress {
                controller.announceStarted(saved.allSatisfy(\.isInProgress))
            } else {
                controller.announceDone(saved.allSatisfy(\.isDone))
            }
        }
        undoManager?.setActionName(name)
    }

    private func announceDone(_ done: Bool) {
        VoiceOver.announce(done ? String(localized: "Marked done") : String(localized: "Marked not done"))
    }

    private func announceStarted(_ started: Bool) {
        VoiceOver.announce(started ? String(localized: "Started") : String(localized: "Stopped"))
    }

    /// Moves checked tasks to Done, leaving the selection in their place.
    private func lingerOut(_ ids: Set<TaskItem.ID>) {
        // An undo or a reopen may have ended the linger already.
        let ids = ids.intersection(lingering)
        guard !ids.isEmpty else { return }
        lingering.subtract(ids)
        if selectionIsWithin(ids), let row = tableView.selectedRowIndexes.first {
            pendingSelection = .slot(row)
        }
        rerender()
    }

    /// The table drops a selected row that moves while offscreen, so the selection follows the tasks it was on.
    private func keepSelection(on ids: Set<TaskItem.ID>) {
        if selectionIsWithin(ids) { pendingSelection = .tasks(ids) }
    }

    /// True when every selected task is leaving, so the table has nothing left to keep selected.
    private func selectionIsWithin(_ ids: Set<TaskItem.ID>) -> Bool {
        let selected = tableView.selectedRowIndexes.compactMap { task(atRow: $0)?.id }
        return !selected.isEmpty && Set(selected).isSubset(of: ids)
    }

    private func add(_ text: String) -> Bool {
        guard let task = store.add(text) else { return false }
        pendingReveal = task.id
        VoiceOver.announce(String(localized: "Added \(task.title)"))
        return true
    }

    private func delete(_ tasks: [TaskItem]) {
        guard !tasks.isEmpty else { return }
        store.delete(Set(tasks.map(\.id)))
        undoManager?.registerUndo(withTarget: self) { $0.restore(tasks) }
        undoManager?.setActionName(String(localized: "Delete"))
        VoiceOver.announce(String(AttributedString(localized: "Deleted ^[\(tasks.count) task](inflect: true)").characters))
    }

    private func restore(_ tasks: [TaskItem]) {
        store.restore(tasks)
        undoManager?.registerUndo(withTarget: self) { $0.delete(tasks) }
        undoManager?.setActionName(String(localized: "Delete"))
        VoiceOver.announce(String(AttributedString(localized: "Restored ^[\(tasks.count) task](inflect: true)").characters))
    }
}

extension TasksViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let targets = targetIDs.compactMap { tasksByID[$0] }
        switch menuItem.action {
        case TaskAction.toggle.selector:
            menuItem.title = TaskAction.toggle.title(done: !targets.isEmpty && targets.allSatisfy(\.isDone))
            return !targets.isEmpty
        case TaskAction.progress.selector:
            let open = targets.filter { !$0.isDone }
            menuItem.title = TaskAction.progress.title(done: false, inProgress: !open.isEmpty && open.allSatisfy(\.isInProgress))
            return !open.isEmpty
        case TaskAction.edit.selector:
            return targets.count == 1
        case TaskAction.copy.selector:
            return !targets.isEmpty
        case TaskAction.delete.selector:
            return !targets.isEmpty
        case DoneAction.toggleSection.selector:
            menuItem.title = DoneAction.toggleSection.title(expanded: showsDone)
            return !store.doneTasks.isEmpty
        case DoneAction.clear.selector:
            return !store.doneTasks.isEmpty
        default:
            return true
        }
    }
}

// MARK: - NSTableViewDelegate

extension TasksViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        task(atRow: row) != nil
    }
}

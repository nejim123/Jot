import Foundation
import Observation
import OSLog

@Observable
final class TaskStore {
    private(set) var tasks: [TaskItem]
    @ObservationIgnored private let file: TaskFile

    init(file: TaskFile) {
        self.file = file
        tasks = file.load()
    }

    var openTasks: [TaskItem] { tasks.filter { !$0.isDone }.sorted(using: TaskItem.listOrder) }

    /// Most recently finished first.
    var doneTasks: [TaskItem] {
        tasks.filter(\.isDone).sorted(using: KeyPathComparator(\.completedAt, order: .reverse))
    }

    @discardableResult
    func add(_ title: String) -> TaskItem? {
        guard let title = title.taskTitle else { return nil }
        let task = TaskItem(title: title)
        tasks.append(task)
        save()
        return task
    }

    func setDone(_ isDone: Bool, for id: TaskItem.ID) {
        update(id) { task in
            guard task.isDone != isDone else { return }
            task.completedAt = isDone ? .now : nil
        }
    }

    /// Tasks started together share a date, so they keep their order. A done task can't be started;
    /// it keeps its start date, so reopening it puts it back in progress.
    func setStarted(_ isStarted: Bool, for ids: Set<TaskItem.ID>) {
        let now = Date.now
        for id in ids {
            update(id) { task in
                guard !task.isDone, task.isInProgress != isStarted else { return }
                task.startedAt = isStarted ? now : nil
            }
        }
    }

    /// Puts back each task's done and in-progress state from saved copies, so undo returns a task to its old place.
    func restoreCompletion(of saved: [TaskItem]) {
        for task in saved {
            update(task.id) { restored in
                restored.startedAt = task.startedAt
                restored.completedAt = task.completedAt
            }
        }
    }

    func rename(_ id: TaskItem.ID, to title: String) {
        guard let title = title.taskTitle else { return }
        update(id) { $0.title = title }
    }

    func delete(_ ids: Set<TaskItem.ID>) {
        tasks.removeAll { ids.contains($0.id) }
        save()
    }

    /// Puts deleted tasks back in their original order.
    func restore(_ restored: [TaskItem]) {
        let existing = Set(tasks.map(\.id))
        tasks = (tasks + restored.filter { !existing.contains($0.id) }).sorted(using: KeyPathComparator(\.createdAt))
        save()
    }

    private func update(_ id: TaskItem.ID, _ change: (inout TaskItem) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var task = tasks[index]
        change(&task)
        guard task != tasks[index] else { return }
        tasks[index] = task
        save()
    }

    private func save() {
        do {
            try file.save(tasks)
        } catch {
            Logger.store.error("Saving tasks failed: \(error)")
        }
    }
}

import Foundation

nonisolated struct TaskItem: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var title: String
    let createdAt: Date
    var startedAt: Date?
    var completedAt: Date?

    init(title: String, createdAt: Date = .now) {
        id = UUID()
        self.title = title
        self.createdAt = createdAt
    }

    var isDone: Bool { completedAt != nil }
    var isInProgress: Bool { startedAt != nil && !isDone }

    /// Started tasks first, most recent on top, then newest first, so new work lands right under the add field.
    static var listOrder: [KeyPathComparator<TaskItem>] {
        [KeyPathComparator(\.startedAt, order: .reverse), KeyPathComparator(\.createdAt, order: .reverse)]
    }
}

nonisolated extension String {
    /// The text trimmed for use as a task title, or nil when nothing is left.
    var taskTitle: String? {
        let title = trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }
}

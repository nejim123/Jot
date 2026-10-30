import Foundation
import OSLog

/// The JSON file that holds every task. A file it can't read is moved aside, never overwritten.
nonisolated struct TaskFile: Sendable {
    let url: URL

    static let standard = TaskFile(url: .applicationSupportDirectory.appending(path: "tasks.json"))

    func load() -> [TaskItem] {
        do {
            var seen = Set<TaskItem.ID>()
            return try JSONDecoder().decode([TaskItem].self, from: Data(contentsOf: url))
                .filter { seen.insert($0.id).inserted }
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        } catch {
            quarantine(after: error)
            return []
        }
    }

    func save(_ tasks: [TaskItem]) throws {
        let data = try JSONEncoder().encode(tasks)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func quarantine(after error: any Error) {
        let backup = url.deletingPathExtension().appendingPathExtension("unreadable-\(Int(Date.now.timeIntervalSince1970)).json")
        do {
            try FileManager.default.moveItem(at: url, to: backup)
            Logger.store.error("Moved unreadable tasks to \(backup.lastPathComponent): \(error)")
        } catch {
            Logger.store.fault("Couldn't move unreadable tasks aside: \(error)")
        }
    }
}

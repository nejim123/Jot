import Foundation
import Testing
@testable import Jot

struct TaskStoreTests {
    private let file = TaskFile(url: .temporaryDirectory.appending(path: "\(UUID().uuidString)/tasks.json"))

    @Test func addTrimsAndSkipsBlankText() {
        let store = TaskStore(file: file)
        #expect(store.add("  Call the dentist \n")?.title == "Call the dentist")
        #expect(store.add("   ") == nil)
        #expect(store.tasks.map(\.title) == ["Call the dentist"])
    }

    @Test func openAndDoneTasksShowNewestFirst() {
        let store = TaskStore(file: file)
        let milk = store.add("Buy oat milk")!
        let deck = store.add("Send Sam the deck")!
        let flights = store.add("Book flights")!

        store.setDone(true, for: deck.id)
        store.setDone(true, for: milk.id)

        #expect(store.openTasks.map(\.id) == [flights.id])
        #expect(store.doneTasks.map(\.id) == [milk.id, deck.id])

        store.setDone(false, for: milk.id)
        #expect(store.openTasks.map(\.id) == [flights.id, milk.id])
    }

    @Test func restoringCompletionPutsATaskBackInItsDoneSlot() {
        let store = TaskStore(file: file)
        let bill = store.add("Pay the electricity bill")!
        let plants = store.add("Water the plants")!
        store.setDone(true, for: bill.id)
        store.setDone(true, for: plants.id)
        let saved = store.doneTasks.filter { $0.id == bill.id }

        store.setDone(false, for: bill.id)
        store.restoreCompletion(of: saved)

        #expect(store.doneTasks.map(\.id) == [plants.id, bill.id])
        #expect(store.doneTasks.last?.completedAt == saved.first?.completedAt)
    }

    @Test func startedTasksLeadTheOpenList() {
        let store = TaskStore(file: file)
        let milk = store.add("Buy oat milk")!
        let deck = store.add("Send Sam the deck")!
        let flights = store.add("Book flights")!

        store.setStarted(true, for: [milk.id])
        store.setStarted(true, for: [deck.id])
        #expect(store.openTasks.map(\.id) == [deck.id, milk.id, flights.id])

        store.setStarted(false, for: [deck.id])
        #expect(store.openTasks.map(\.id) == [milk.id, flights.id, deck.id])
    }

    @Test func tasksStartedTogetherKeepTheirOrder() {
        let store = TaskStore(file: file)
        let milk = store.add("Buy oat milk")!
        let deck = store.add("Send Sam the deck")!
        let flights = store.add("Book flights")!

        store.setStarted(true, for: [milk.id, deck.id])
        #expect(store.openTasks.map(\.id) == [deck.id, milk.id, flights.id])
    }

    @Test func reopeningAStartedTaskPutsItBackInProgress() {
        let store = TaskStore(file: file)
        let task = store.add("Draft the pitch")!
        store.setStarted(true, for: [task.id])
        let startedAt = store.tasks[0].startedAt
        store.setDone(true, for: task.id)
        #expect(!store.tasks[0].isInProgress)

        store.setStarted(true, for: [task.id])
        store.setDone(false, for: task.id)
        #expect(store.tasks[0].isInProgress)
        #expect(store.tasks[0].startedAt == startedAt)
    }

    @Test func restoringCompletionPutsBackTheStartDate() {
        let store = TaskStore(file: file)
        let task = store.add("Fix the login bug")!
        let saved = store.tasks

        store.setStarted(true, for: [task.id])
        store.restoreCompletion(of: saved)
        #expect(store.tasks == saved)
    }

    @Test func settingTheSameDoneStateKeepsTheCompletionDate() {
        let store = TaskStore(file: file)
        let task = store.add("Water plants")!
        store.setDone(true, for: task.id)
        let completedAt = store.tasks[0].completedAt
        store.setDone(true, for: task.id)
        #expect(store.tasks[0].completedAt == completedAt)
    }

    @Test func renameTrimsAndIgnoresBlankText() {
        let store = TaskStore(file: file)
        let task = store.add("Email Sam")!
        store.rename(task.id, to: "  Email Sam the Q3 deck ")
        store.rename(task.id, to: "  ")
        #expect(store.tasks[0].title == "Email Sam the Q3 deck")
    }

    @Test func restorePutsDeletedTasksBackInOrder() {
        let store = TaskStore(file: file)
        let first = store.add("First")!
        let second = store.add("Second")!
        let third = store.add("Third")!

        store.delete([first.id, third.id])
        #expect(store.tasks.map(\.id) == [second.id])

        store.restore([third, first])
        store.restore([first])
        #expect(store.tasks.map(\.id) == [first.id, second.id, third.id])
    }

    @Test func tasksSurviveARelaunch() {
        let store = TaskStore(file: file)
        let task = store.add("Renew passport")!
        store.setDone(true, for: task.id)

        let relaunched = TaskStore(file: file)
        #expect(relaunched.tasks == store.tasks)
    }

    @Test func unreadableFileIsMovedAsideNotOverwritten() throws {
        let folder = file.url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let garbage = Data("not json".utf8)
        try garbage.write(to: file.url)

        let store = TaskStore(file: file)
        #expect(store.tasks.isEmpty)
        store.add("New task")

        let backups = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains("unreadable") }
        #expect(backups.count == 1)
        #expect(try Data(contentsOf: #require(backups.first)) == garbage)
    }

    @Test func duplicateIDsInTheFileLoadOnce() throws {
        let task = TaskItem(title: "Only once")
        try file.save([task, task])
        #expect(TaskStore(file: file).tasks == [task])
    }
}

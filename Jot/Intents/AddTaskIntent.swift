import AppIntents

struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Task"
    static let description = IntentDescription("Saves a task to your Jot list.")
    static let authenticationPolicy = IntentAuthenticationPolicy.requiresAuthentication

    @Parameter(title: "Task", requestValueDialog: "What do you need to do?")
    var task: String

    @Dependency private var store: TaskStore

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$task) to Jot")
    }

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let added = store.add(task) else { throw $task.needsValueError() }
        return .result(dialog: "Added \(added.title).")
    }
}

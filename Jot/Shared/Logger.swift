import OSLog

nonisolated extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Jot"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let store = Logger(subsystem: subsystem, category: "store")
}

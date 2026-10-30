import AppKit

/// Jot's type, spacing and shape. Colors come from system roles so Increase Contrast holds.
enum Style {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 24
    /// Matches the inset table's own selection shape, so hover and selection line up.
    static let rowInset: CGFloat = 10
    static let rowRadius: CGFloat = 8
    /// The smallest click target the macOS guidelines allow.
    static let minimumHitHeight: CGFloat = 20
    /// A small pill holding one icon, like a task's copy button.
    static let iconPillSize = NSSize(width: 28, height: 22)

    enum Font {
        static let title = rounded(20, .bold)
        static let subtitle = NSFont.systemFont(ofSize: 12, weight: .medium)
        static let task = NSFont.systemFont(ofSize: 14)
        static let field = NSFont.systemFont(ofSize: 14)
        static let section = rounded(13, .semibold)
        static let count = rounded(12, .semibold, monospacedDigits: true)
        static let emptyTitle = rounded(15, .semibold)
        static let hint = NSFont.systemFont(ofSize: 11)
    }

    private static func rounded(_ size: CGFloat, _ weight: NSFont.Weight, monospacedDigits: Bool = false) -> NSFont {
        let base = monospacedDigits
            ? NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
            : NSFont.systemFont(ofSize: size, weight: weight)
        return base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
    }
}

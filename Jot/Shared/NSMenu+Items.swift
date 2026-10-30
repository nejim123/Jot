import AppKit

extension NSMenu {
    convenience init(_ title: String, items: [NSMenuItem]) {
        self.init(title: title)
        items.forEach(addItem)
    }
}

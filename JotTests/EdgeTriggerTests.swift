import AppKit
import Testing
@testable import Jot

struct EdgeTriggerTests {
    private let laptop = (frame: NSRect(x: 0, y: 0, width: 1728, height: 1117), visible: NSRect(x: 0, y: 0, width: 1728, height: 1084))
    private let external = (frame: NSRect(x: 1728, y: 0, width: 1920, height: 1080), visible: NSRect(x: 1728, y: 0, width: 1920, height: 1080))

    private func zone(_ x: CGFloat, _ y: CGFloat, screens: [(frame: NSRect, visible: NSRect)]) -> Int? {
        EdgeTrigger.zoneIndex(for: NSPoint(x: x, y: y), in: screens) { _ in 520 }
    }

    @Test func topOfTheRightEdgeTriggers() {
        #expect(zone(1727.5, 1117, screens: [laptop]) == 0)
        #expect(zone(1727.5, 1110, screens: [laptop]) == 0)
        #expect(zone(1727.5, 600, screens: [laptop]) == 0)
    }

    @Test func belowTheDrawerOrAwayFromTheEdgeDoesNot() {
        #expect(zone(1727.5, 564, screens: [laptop]) == nil)
        #expect(zone(1727.5, 500, screens: [laptop]) == nil)
        #expect(zone(1700, 1000, screens: [laptop]) == nil)
    }

    @Test func anEdgeSharedWithAnotherScreenDoesNot() {
        #expect(zone(1727.5, 1000, screens: [laptop, external]) == nil)
        #expect(zone(3647.5, 1000, screens: [laptop, external]) == 1)
    }
}

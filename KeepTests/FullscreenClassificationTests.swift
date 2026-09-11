import Foundation
import Testing
@testable import Keep

struct FullscreenClassificationTests {
    private let displayA = DisplayGeometry(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
    )
    private let displayB = DisplayGeometry(
        id: 2,
        frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1055)
    )

    @Test func trueFullscreenMatchesScreenFrameNotVisibleFrame() {
        #expect(
            FullscreenClassification.covering(windowBounds: displayA.frame, display: displayA) == .trueFullscreen
        )
        #expect(
            FullscreenClassification.shouldPauseDisplay(covering: .trueFullscreen, pauseWhenFullscreen: true)
        )
    }

    @Test func maximizedMatchesVisibleFrameAndDoesNotPause() {
        #expect(
            FullscreenClassification.covering(windowBounds: displayA.visibleFrame, display: displayA) == .maximized
        )
        #expect(
            FullscreenClassification.shouldPauseDisplay(covering: .maximized, pauseWhenFullscreen: true) == false
        )
    }

    @Test func keepProcessNeverCountsAsCoveringEvenWhenLabFillsTheDisplay() {
        let lab = ObservedWindow(ownerPID: 42, layer: 0, bounds: displayA.frame)
        let occupancy = FullscreenClassification.occupancy(
            windows: [lab],
            displays: [displayA],
            ownPID: 42
        )
        #expect(occupancy[1] == .clear)
    }

    @Test func fullscreenOnOneDisplayLeavesTheOtherClear() {
        let safari = ObservedWindow(ownerPID: 99, layer: 0, bounds: displayB.frame)
        let occupancy = FullscreenClassification.occupancy(
            windows: [safari],
            displays: [displayA, displayB],
            ownPID: 42
        )
        #expect(occupancy[1] == .clear)
        #expect(occupancy[2] == .trueFullscreen)
        #expect(FullscreenClassification.shouldPauseDisplay(covering: occupancy[1]!, pauseWhenFullscreen: true) == false)
        #expect(FullscreenClassification.shouldPauseDisplay(covering: occupancy[2]!, pauseWhenFullscreen: true))
    }

    @Test func pauseWhenFullscreenOptOut() {
        #expect(
            FullscreenClassification.shouldPauseDisplay(covering: .trueFullscreen, pauseWhenFullscreen: false) == false
        )
    }

    @Test func cgWindowBoundsConvertFromTopLeftPrimary() {
        let cg = CGRect(x: 10, y: 0, width: 100, height: 50)
        let cocoa = FullscreenClassification.cocoaRect(fromCGWindowBounds: cg, primaryHeight: 900)
        #expect(cocoa.origin.x == 10)
        #expect(cocoa.origin.y == 850)
        #expect(cocoa.width == 100)
        #expect(cocoa.height == 50)
    }
}

import Foundation

enum DisplayCovering: Equatable, Sendable {
    case clear
    case maximized
    case trueFullscreen

    var labName: String {
        switch self {
        case .clear: return "clear"
        case .maximized: return "maximized"
        case .trueFullscreen: return "true fullscreen"
        }
    }

    static func stronger(_ a: DisplayCovering, _ b: DisplayCovering) -> DisplayCovering {
        switch (a, b) {
        case (.trueFullscreen, _), (_, .trueFullscreen):
            return .trueFullscreen
        case (.maximized, _), (_, .maximized):
            return .maximized
        default:
            return .clear
        }
    }
}

struct ObservedWindow: Equatable, Sendable {
    var ownerPID: Int32
    var layer: Int
    var bounds: CGRect
}

struct DisplayGeometry: Equatable, Sendable {
    var id: UInt32
    var frame: CGRect
    var visibleFrame: CGRect
}

/// Keep product policy: pause wallpaper only for true fullscreen on that display.
/// Maximized/zoomed windows match `visibleFrame`, not `frame`. Our own PID (Lab) never counts.
enum FullscreenClassification {
    static let tolerance: CGFloat = 8

    /// CGWindowList origin is top left of the primary display; AppKit is bottom left.
    static func cocoaRect(fromCGWindowBounds bounds: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: bounds.origin.x,
            y: primaryHeight - bounds.origin.y - bounds.height,
            width: bounds.width,
            height: bounds.height
        )
    }

    static func covering(
        windowBounds: CGRect,
        display: DisplayGeometry,
        tolerance: CGFloat = tolerance
    ) -> DisplayCovering {
        if approximatelyEqual(windowBounds, display.frame, tolerance: tolerance) {
            return .trueFullscreen
        }
        if approximatelyEqual(windowBounds, display.visibleFrame, tolerance: tolerance) {
            return .maximized
        }
        return .clear
    }

    static func occupancy(
        windows: [ObservedWindow],
        displays: [DisplayGeometry],
        ownPID: Int32
    ) -> [UInt32: DisplayCovering] {
        var result: [UInt32: DisplayCovering] = [:]
        for display in displays {
            result[display.id] = .clear
        }
        for window in windows where window.layer == 0 && window.ownerPID != ownPID {
            for display in displays {
                let next = covering(windowBounds: window.bounds, display: display)
                result[display.id] = DisplayCovering.stronger(result[display.id] ?? .clear, next)
            }
        }
        return result
    }

    static func shouldPauseDisplay(
        covering: DisplayCovering,
        pauseWhenFullscreen: Bool
    ) -> Bool {
        pauseWhenFullscreen && covering == .trueFullscreen
    }

    private static func approximatelyEqual(_ a: CGRect, _ b: CGRect, tolerance: CGFloat) -> Bool {
        abs(a.origin.x - b.origin.x) <= tolerance
            && abs(a.origin.y - b.origin.y) <= tolerance
            && abs(a.width - b.width) <= tolerance
            && abs(a.height - b.height) <= tolerance
    }
}

import AppKit
import Combine
import os
import QuartzCore

enum FrameClockAttachment: Equatable, Sendable {
    case none
    case window
    case screen
}

/// Counts display-link ticks into a whole-number fps over a one second window.
struct FrameRateMeter: Equatable, Sendable {
    private(set) var framesPerSecond = 0
    private var framesInWindow = 0
    private var windowStart: CFTimeInterval

    init(now: CFTimeInterval = CACurrentMediaTime()) {
        windowStart = now
    }

    static let windowDuration: CFTimeInterval = 1
    static let minimumFramesPerSecond: Float = 20
    static let maximumFramesPerSecond: Float = 30
    static let preferredFramesPerSecond: Float = 24

    mutating func recordFrame(now: CFTimeInterval) {
        framesInWindow += 1
        let elapsed = now - windowStart
        guard elapsed >= Self.windowDuration else { return }
        framesPerSecond = Int((Double(framesInWindow) / elapsed).rounded())
        framesInWindow = 0
        windowStart = now
    }

    mutating func reset(now: CFTimeInterval = CACurrentMediaTime()) {
        framesPerSecond = 0
        framesInWindow = 0
        windowStart = now
    }
}

/// Frame times for the living scene. Desktop wallpaper uses `NSWindow.displayLink`.
/// Lab preview may attach to `NSScreen.displayLink`. That is not the wallpaper clock.
@MainActor
final class FrameClock: NSObject, ObservableObject {
    @Published private(set) var date = Date()

    private(set) var attachment: FrameClockAttachment = .none
    private(set) var stepCount: UInt64 = 0
    private(set) var framesPerSecond = 0
    private var rateMeter = FrameRateMeter()

    var isPaused = false {
        didSet {
            displayLink?.isPaused = isPaused
            if isPaused {
                rateMeter.reset()
                framesPerSecond = 0
            }
        }
    }

    private var displayLink: CADisplayLink?
    /// Last policy applied. Signposts fire only when this changes, or when the link must be reinstalled.
    private var lastDesktopPolicy: WallpaperDisplayLinkPolicy.State?

    var isLinkInstalled: Bool { displayLink != nil }

    func attach(to window: NSWindow) {
        detach()
        let link = window.displayLink(target: self, selector: #selector(step(_:)))
        attachment = .window
        configure(link)
    }

    func attach(to screen: NSScreen) {
        detach()
        let link = screen.displayLink(target: self, selector: #selector(step(_:)))
        attachment = .screen
        configure(link)
    }

    func applyDesktopPolicy(_ state: WallpaperDisplayLinkPolicy.State, window: NSWindow) {
        switch state {
        case .detached:
            let shouldSignpost = lastDesktopPolicy != .detached || isLinkInstalled
            if shouldSignpost {
                KeepLog.wallpaperSignpost.withIntervalSignpost("detach") {
                    isPaused = true
                    detach()
                }
            } else {
                isPaused = true
                detach()
            }
        case .attached(let paused):
            let needsAttach = attachment != .window || displayLink == nil
            if needsAttach {
                KeepLog.wallpaperSignpost.withIntervalSignpost("attach") {
                    attach(to: window)
                }
            }
            if isPaused != paused {
                if paused {
                    KeepLog.wallpaperSignpost.withIntervalSignpost("pause") {
                        isPaused = true
                    }
                } else {
                    KeepLog.wallpaperSignpost.withIntervalSignpost("resume") {
                        isPaused = false
                    }
                }
            } else {
                isPaused = paused
            }
        }
        lastDesktopPolicy = state
    }

    func detach() {
        displayLink?.invalidate()
        displayLink = nil
        attachment = .none
        rateMeter.reset()
        framesPerSecond = 0
    }

    private func configure(_ link: CADisplayLink) {
        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: FrameRateMeter.minimumFramesPerSecond,
            maximum: FrameRateMeter.maximumFramesPerSecond,
            preferred: FrameRateMeter.preferredFramesPerSecond
        )
        link.isPaused = isPaused
        link.add(to: .main, forMode: .common)
        displayLink = link
        KeepLog.wallpaper.debug("Display link attached source=\(String(describing: self.attachment)) paused=\(self.isPaused)")
    }

    @objc private func step(_ link: CADisplayLink) {
        stepCount += 1
        date = Date()
        rateMeter.recordFrame(now: CACurrentMediaTime())
        framesPerSecond = rateMeter.framesPerSecond
    }
}

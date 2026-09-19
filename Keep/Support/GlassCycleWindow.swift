import AppKit
import ScreenCaptureKit
import SwiftUI

/// Lab window that plays or records the Liquid Glass sun cycle.
@MainActor
enum GlassCycleWindow {
    private static var window: NSWindow?
    private static var driver: GlassCycleDriver?

    static func presentLive(session: AppSession) {
        NSApp.setActivationPolicy(.regular)
        let live = GlassCycleLiveView(observer: session.location.fix.solarObserver)
        let hosting = NSHostingController(rootView: live)
        let panel = makePanel(hosting: hosting, title: "Keep glass cycle")
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = panel
    }

    static func record(session: AppSession, thenQuit: Bool) async {
        NSApp.setActivationPolicy(.regular)
        session.wallpaper.setVisible(false)
        let folder = outputFolder()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        func note(_ line: String) {
            let url = folder.appendingPathComponent("record-log.txt")
            let text = line + "\n"
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(Data(text.utf8))
                try? handle.close()
            } else {
                try? text.write(to: url, atomically: true, encoding: .utf8)
            }
            KeepLog.session.info("\(line, privacy: .public)")
        }

        let cycleDriver = GlassCycleDriver()
        driver = cycleDriver
        let hosting = NSHostingController(
            rootView: GlassCycleDrivenHost(
                driver: cycleDriver,
                observer: session.location.fix.solarObserver
            )
        )
        let panel = makePanel(hosting: hosting, title: "Keep glass cycle")
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = panel
        NSCursor.hide()
        defer { NSCursor.unhide() }

        if !CGPreflightScreenCaptureAccess() {
            note("requesting screen capture access")
            _ = CGRequestScreenCaptureAccess()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        note("capture allowed \(CGPreflightScreenCaptureAccess())")
        try? await Task.sleep(nanoseconds: 400_000_000)

        let filter = await windowFilter(for: panel)
        note("shareable window \(filter != nil)")

        let frames = GlassCycleFilm.frameCount
        let step = UInt64(1_000_000_000 / GlassCycleFilm.framesPerSecond)
        var wrote = 0
        for index in 0..<frames {
            cycleDriver.progress = Double(index) / Double(max(1, frames - 1))
            driveInteractiveGlass(
                panel: panel,
                progress: cycleDriver.progress,
                observer: session.location.fix.solarObserver
            )
            panel.displayIfNeeded()
            try? await Task.sleep(nanoseconds: step)
            guard let image = await grab(panel: panel, filter: filter, hosting: hosting.view) else {
                if index == 0 { note("first frame missing") }
                continue
            }
            let name = String(format: "native-%04d.png", index + 1)
            do {
                try DayFilm.writePNG(image, to: folder.appendingPathComponent(name))
                wrote += 1
            } catch {
                note("png write failed")
            }
        }
        note("wrote \(wrote) frames at \(folder.path)")
        FileHandle.standardError.write(Data("KEEP_GLASS_CYCLE_WROTE=\(folder.path)\n".utf8))
        if thenQuit {
            NSApp.terminate(nil)
        }
    }

    private static func makePanel(hosting: NSViewController, title: String) -> NSWindow {
        let panel = NSWindow(contentViewController: hosting)
        panel.title = title
        panel.styleMask = [.borderless, .fullSizeContentView]
        panel.setContentSize(GlassCycleFilm.canvas)
        panel.contentMinSize = GlassCycleFilm.canvas
        panel.contentMaxSize = GlassCycleFilm.canvas
        panel.center()
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .black
        panel.isOpaque = true
        panel.hasShadow = false
        panel.sharingType = .readOnly
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        return panel
    }

    private static func driveInteractiveGlass(panel: NSWindow, progress: Double, observer: SolarObserver) {
        let date = GlassCycleFilm.civilDate(progress: progress, near: Date(), observer: observer)
        let solar = SolarEngine.context(at: date, observer: observer)
        let sun = DaySceneView.bodyPoint(
            size: GlassCycleFilm.canvas,
            progress: solar.isDay ? solar.sunProgress : solar.moonProgress,
            readability: .glassCycle
        )
        guard let content = panel.contentView else { return }
        let scaleX = content.bounds.width / GlassCycleFilm.canvas.width
        let scaleY = content.bounds.height / GlassCycleFilm.canvas.height
        let viewPoint = NSPoint(x: sun.x * scaleX, y: content.bounds.height - sun.y * scaleY)
        let windowPoint = content.convert(viewPoint, to: nil)
        let cocoa = panel.convertToScreen(NSRect(origin: windowPoint, size: .zero)).origin
        let top = panel.screen?.frame.maxY ?? NSScreen.main?.frame.maxY ?? cocoa.y
        CGWarpMouseCursorPosition(CGPoint(x: cocoa.x, y: top - cocoa.y))
    }

    private static func windowFilter(for window: NSWindow) async -> SCContentFilter? {
        guard #available(macOS 14.2, *) else { return nil }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
            if let match = content.windows.first(where: { $0.windowID == UInt32(window.windowNumber) }) {
                return SCContentFilter(desktopIndependentWindow: match)
            }
        } catch {
            KeepLog.session.error("Shareable content unavailable")
        }
        return nil
    }

    private static func grab(panel: NSWindow, filter: SCContentFilter?, hosting: NSView) async -> CGImage? {
        if #available(macOS 14.2, *), let filter {
            let config = SCStreamConfiguration()
            let scale = panel.backingScaleFactor
            let pixel = panel.frame.size
            config.width = max(1, Int(pixel.width * scale))
            config.height = max(1, Int(pixel.height * scale))
            config.showsCursor = false
            config.capturesAudio = false
            if let image = try? await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) {
                return image
            }
        }
        let id = CGWindowID(panel.windowNumber)
        if let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            id,
            [.bestResolution, .boundsIgnoreFraming]
        ) {
            return image
        }
        return viewImage(hosting)
    }

    private static func viewImage(_ view: NSView) -> CGImage? {
        let bounds = view.bounds
        guard bounds.width > 1, bounds.height > 1 else { return nil }
        guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        view.cacheDisplay(in: bounds, to: rep)
        return rep.cgImage
    }

    private static func outputFolder() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("KeepGlassCycle", isDirectory: true)
    }
}

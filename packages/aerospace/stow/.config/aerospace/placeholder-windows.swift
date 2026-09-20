import AppKit

final class PlaceholderWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.screens.first(where: {
            $0.localizedName == "LG HDR DQHD" ||
            (Int($0.frame.width) == 5120 && Int($0.frame.height) == 1440)
        }) else {
            NSApp.terminate(nil)
            return
        }

        let widths: [CGFloat] = [1280, 2560, 1280]
        let names = ["Left 1280", "Center 2560", "Right 1280"]
        let colors = [
            NSColor.systemGray.withAlphaComponent(0.16),
            NSColor.systemBlue.withAlphaComponent(0.12),
            NSColor.systemGray.withAlphaComponent(0.16),
        ]

        var x = screen.frame.minX
        for index in widths.indices {
            let rect = NSRect(x: x, y: screen.frame.minY, width: widths[index], height: 1440)
            let window = PlaceholderWindow(
                contentRect: rect,
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.title = "AeroSpace Placeholder — \(names[index])"
            window.identifier = NSUserInterfaceItemIdentifier("aerospace-placeholder-\(index)")
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.managed, .participatesInCycle]
            window.backgroundColor = colors[index]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .visible
            window.minSize = NSSize(width: 80, height: 80)
            window.setFrame(rect, display: true)
            window.orderFrontRegardless()
            windows.append(window)
            x += widths[index]
            if index < widths.count - 1 {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.15))
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

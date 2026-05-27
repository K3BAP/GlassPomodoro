import SwiftUI
import AppKit

/// A borderless window that can still become key so overlay buttons / Esc work.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Shows a full-screen blurred break countdown across all displays.
@MainActor
final class BreakOverlayController {
    private var windows: [NSWindow] = []
    private var keyMonitor: Any?
    private weak var engine: PomodoroEngine?

    /// Drive visibility from the engine's active phase.
    func update(isBreak: Bool, engine: PomodoroEngine, enabled: Bool) {
        if isBreak && enabled {
            show(engine: engine)
        } else {
            hide()
        }
    }

    private func show(engine: PomodoroEngine) {
        guard windows.isEmpty else { return }
        self.engine = engine

        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.isReleasedWhenClosed = false

            let host = NSHostingView(rootView: BreakOverlayView(engine: engine))
            host.frame = CGRect(origin: .zero, size: screen.frame.size)
            host.autoresizingMask = [.width, .height]
            window.contentView = host
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.engine?.endBreak()
                return nil
            }
            return event
        }
    }

    private func hide() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
    }
}

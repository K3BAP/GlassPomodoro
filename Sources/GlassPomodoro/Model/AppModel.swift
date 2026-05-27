import SwiftUI
import Observation

/// Owns the settings + engine and wires engine announcements to system services.
@Observable
@MainActor
final class AppModel {
    let settings: Settings
    let engine: PomodoroEngine
    private let overlay = BreakOverlayController()

    init() {
        let settings = Settings.load()
        self.settings = settings
        self.engine = PomodoroEngine(settings: settings)

        engine.onAnnounce = { [settings] title, body, phase in
            if settings.soundEnabled {
                SoundPlayer.play(for: phase)
            }
            if settings.notificationsEnabled {
                NotificationService.post(title: title, body: body)
            }
        }

        engine.onOverlayStateChanged = { [weak self] in
            guard let self else { return }
            self.overlay.update(
                visible: self.engine.isOverlayActive,
                engine: self.engine,
                enabled: self.settings.fullScreenBreakOverlay
            )
        }

        if settings.notificationsEnabled {
            NotificationService.requestAuthorization()
        }
        LaunchAtLogin.set(settings.launchAtLogin)
    }

    /// Persist settings and reconcile side effects after the user edits them.
    func settingsChanged() {
        settings.save()
        LaunchAtLogin.set(settings.launchAtLogin)
        if settings.notificationsEnabled {
            NotificationService.requestAuthorization()
        }
    }

    /// Short label shown next to the menu bar icon. Shows the remaining time only
    /// during focus; breaks are handled by the full-screen overlay, so the menu bar
    /// stays icon-only then.
    var menuBarTitle: String? {
        guard settings.showMenuBarCountdown else { return nil }
        if engine.breakPromptActive { return "Break?" }
        return engine.phase == .focus ? engine.timeString : nil
    }
}

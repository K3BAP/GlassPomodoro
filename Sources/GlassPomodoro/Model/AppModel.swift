import SwiftUI
import Observation

/// Owns the settings + engine and wires engine announcements to system services.
@Observable
@MainActor
final class AppModel {
    let settings: Settings
    let engine: PomodoroEngine

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

    /// Short label shown next to the menu bar icon.
    var menuBarTitle: String? {
        guard settings.showMenuBarCountdown else { return nil }
        if engine.breakPromptActive { return "Break?" }
        return engine.timeString
    }
}

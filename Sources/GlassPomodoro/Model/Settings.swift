import SwiftUI
import Observation

/// User-configurable settings, persisted to `UserDefaults` as a single JSON blob.
@Observable
final class Settings: Codable {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var iterationsBeforeLongBreak: Int = 4

    var snoozeMinutes: Int = 5
    var promptCountdownSeconds: Int = 10

    var autoStartFocus: Bool = true

    var soundEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var launchAtLogin: Bool = false
    var showMenuBarCountdown: Bool = true
    var fullScreenBreakOverlay: Bool = true

    init() {}

    // MARK: Codable (exclude Observation internals)

    enum CodingKeys: String, CodingKey {
        case focusMinutes, shortBreakMinutes, longBreakMinutes, iterationsBeforeLongBreak
        case snoozeMinutes, promptCountdownSeconds
        case autoStartFocus
        case soundEnabled, notificationsEnabled, launchAtLogin, showMenuBarCountdown
        case fullScreenBreakOverlay
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        focusMinutes = try c.decodeIfPresent(Int.self, forKey: .focusMinutes) ?? 25
        shortBreakMinutes = try c.decodeIfPresent(Int.self, forKey: .shortBreakMinutes) ?? 5
        longBreakMinutes = try c.decodeIfPresent(Int.self, forKey: .longBreakMinutes) ?? 15
        iterationsBeforeLongBreak = try c.decodeIfPresent(Int.self, forKey: .iterationsBeforeLongBreak) ?? 4
        snoozeMinutes = try c.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? 5
        promptCountdownSeconds = try c.decodeIfPresent(Int.self, forKey: .promptCountdownSeconds) ?? 10
        autoStartFocus = try c.decodeIfPresent(Bool.self, forKey: .autoStartFocus) ?? true
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showMenuBarCountdown = try c.decodeIfPresent(Bool.self, forKey: .showMenuBarCountdown) ?? true
        fullScreenBreakOverlay = try c.decodeIfPresent(Bool.self, forKey: .fullScreenBreakOverlay) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(focusMinutes, forKey: .focusMinutes)
        try c.encode(shortBreakMinutes, forKey: .shortBreakMinutes)
        try c.encode(longBreakMinutes, forKey: .longBreakMinutes)
        try c.encode(iterationsBeforeLongBreak, forKey: .iterationsBeforeLongBreak)
        try c.encode(snoozeMinutes, forKey: .snoozeMinutes)
        try c.encode(promptCountdownSeconds, forKey: .promptCountdownSeconds)
        try c.encode(autoStartFocus, forKey: .autoStartFocus)
        try c.encode(soundEnabled, forKey: .soundEnabled)
        try c.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try c.encode(launchAtLogin, forKey: .launchAtLogin)
        try c.encode(showMenuBarCountdown, forKey: .showMenuBarCountdown)
        try c.encode(fullScreenBreakOverlay, forKey: .fullScreenBreakOverlay)
    }

    // MARK: Persistence

    private static let storageKey = "settings.v1"

    static func load() -> Settings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(Settings.self, from: data) else {
            return Settings()
        }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func duration(for phase: Phase) -> Int {
        switch phase {
        case .focus: return max(1, focusMinutes) * 60
        case .shortBreak: return max(1, shortBreakMinutes) * 60
        case .longBreak: return max(1, longBreakMinutes) * 60
        }
    }
}

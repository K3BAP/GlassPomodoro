import AppKit

enum SoundPlayer {
    /// Plays a subtle built-in system sound for a phase transition.
    static func play(for phase: Phase) {
        let name: String
        switch phase {
        case .focus: name = "Submarine"
        case .shortBreak: name = "Tink"
        case .longBreak: name = "Glass"
        }
        NSSound(named: name)?.play()
    }
}

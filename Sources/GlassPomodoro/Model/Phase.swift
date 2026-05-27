import SwiftUI

/// A single stage of the Pomodoro cycle.
enum Phase: String, Codable, CaseIterable {
    case focus
    case shortBreak
    case longBreak

    var isBreak: Bool { self != .focus }

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var symbolName: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "figure.walk"
        }
    }

    /// Tint applied to the Liquid Glass surfaces for this phase.
    var tint: Color {
        switch self {
        case .focus: return Color(red: 0.92, green: 0.38, blue: 0.36)   // warm red
        case .shortBreak: return Color(red: 0.30, green: 0.74, blue: 0.55) // green
        case .longBreak: return Color(red: 0.36, green: 0.58, blue: 0.95)  // blue
        }
    }
}

import SwiftUI
import Observation

@Observable
@MainActor
final class PomodoroEngine {
    // MARK: Observable state

    private(set) var phase: Phase = .focus
    private(set) var secondsRemaining: Int
    private(set) var currentPhaseTotal: Int
    private(set) var isRunning: Bool = false

    /// Number of focus sessions completed in the current long-break cycle.
    private(set) var completedFocusCount: Int = 0

    /// Lifetime total of finished focus sessions. Persisted; cleared by `reset()`.
    private(set) var totalFocusSessions: Int = 0

    /// Set when a break is skipped; the next break that begins is doubled.
    private(set) var nextBreakDoubled: Bool = false

    /// True while the "break is due" prompt is shown.
    private(set) var breakPromptActive: Bool = false
    /// The break that will begin once the prompt resolves.
    private(set) var pendingBreakPhase: Phase = .shortBreak
    /// Seconds left before the break auto-starts.
    private(set) var promptCountdownRemaining: Int = 0

    /// True after a break has finished and we are waiting for the user to confirm
    /// they are ready to focus again (instead of auto-resuming).
    private(set) var awaitingFocusConfirmation: Bool = false

    private let settings: Settings
    private var ticker: Task<Void, Never>?

    /// Called for user-facing announcements (title, body, phase used for sound choice).
    var onAnnounce: ((String, String, Phase) -> Void)?

    /// Called whenever the full-screen overlay's visibility may have changed.
    var onOverlayStateChanged: (() -> Void)?

    /// Whether the full-screen overlay should currently be shown.
    var isOverlayActive: Bool {
        breakPromptActive || phase.isBreak || awaitingFocusConfirmation
    }

    private static let totalKey = "stats.totalFocusSessions"

    init(settings: Settings) {
        self.settings = settings
        let total = settings.duration(for: .focus)
        self.secondsRemaining = total
        self.currentPhaseTotal = total
        self.totalFocusSessions = UserDefaults.standard.integer(forKey: Self.totalKey)
    }

    private func recordFinishedFocus() {
        totalFocusSessions += 1
        UserDefaults.standard.set(totalFocusSessions, forKey: Self.totalKey)
    }

    // MARK: Derived

    /// 0...1 progress through the current phase (elapsed fraction).
    var progress: Double {
        guard currentPhaseTotal > 0 else { return 0 }
        return 1.0 - Double(secondsRemaining) / Double(currentPhaseTotal)
    }

    var timeString: String { Self.format(secondsRemaining) }

    static func format(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: User actions

    func startOrPause() {
        guard !breakPromptActive else { return }
        isRunning ? stopTicker() : startTicker()
        isRunning.toggle()
    }

    func reset() {
        stopTicker()
        breakPromptActive = false
        awaitingFocusConfirmation = false
        nextBreakDoubled = false
        completedFocusCount = 0
        totalFocusSessions = 0
        UserDefaults.standard.set(0, forKey: Self.totalKey)
        isRunning = false
        setPhase(.focus, autoStart: false)
        notifyOverlay()
    }

    /// Skip the upcoming break (from the prompt) and double the next break instead.
    func skipBreak() {
        guard breakPromptActive else { return }
        breakPromptActive = false
        nextBreakDoubled = true
        completedFocusCount += 1
        recordFinishedFocus()
        beginFocus(autoStart: true)
    }

    /// End the current break early (from the full-screen overlay) and return to focus.
    func endBreak() {
        guard phase.isBreak else { return }
        beginFocus(autoStart: true)
    }

    /// Confirm readiness and start the next focus session (from the overlay/panel).
    func confirmReadyToFocus() {
        guard awaitingFocusConfirmation else { return }
        awaitingFocusConfirmation = false
        beginFocus(autoStart: true)
    }

    /// Minutes added per snooze, surfaced for the UI labels.
    var snoozeMinutes: Int { max(1, settings.snoozeMinutes) }

    /// Snooze: keep focusing for `snoozeMinutes` more, then prompt again.
    func snooze() {
        guard breakPromptActive else { return }
        breakPromptActive = false
        let added = max(1, settings.snoozeMinutes) * 60
        secondsRemaining += added
        currentPhaseTotal += added
        isRunning = true
        startTicker()
        notifyOverlay()
    }

    /// Begin the due break immediately (from the prompt).
    func startBreakNow() {
        guard breakPromptActive else { return }
        breakPromptActive = false
        beginBreak()
    }

    /// Maps the Esc key to a sensible action for the current overlay state.
    func handleEscape() {
        if breakPromptActive {
            startBreakNow()
        } else if awaitingFocusConfirmation {
            confirmReadyToFocus()
        } else if phase.isBreak {
            endBreak()
        }
    }

    // MARK: Phase transitions

    private func completePhase() {
        if phase == .focus {
            pendingBreakPhase = computeBreakPhase()
            isRunning = false
            stopTicker()
            presentBreakPrompt()
        } else {
            // A break finished. (Focus completion is counted when the break begins or is
            // skipped, not here, to avoid double-counting.)
            if settings.fullScreenBreakOverlay && !settings.autoStartFocus {
                // Wait for the user to confirm they are ready to focus again.
                isRunning = false
                stopTicker()
                awaitingFocusConfirmation = true
                announce("Break over", "Ready to focus when you are.", .focus)
                notifyOverlay()
            } else {
                beginFocus(autoStart: settings.autoStartFocus)
            }
        }
    }

    private func presentBreakPrompt() {
        breakPromptActive = true
        promptCountdownRemaining = max(0, settings.promptCountdownSeconds)
        announce("Time for a break", "Your \(pendingBreakPhase.title.lowercased()) is ready.", pendingBreakPhase)
        notifyOverlay()
        startTicker()   // ticker drives the prompt countdown to an automatic start
    }

    private func computeBreakPhase() -> Phase {
        let iters = max(1, settings.iterationsBeforeLongBreak)
        return (completedFocusCount + 1) % iters == 0 ? .longBreak : .shortBreak
    }

    private func beginBreak() {
        completedFocusCount += 1
        recordFinishedFocus()
        let base = settings.duration(for: pendingBreakPhase)
        let total = nextBreakDoubled ? base * 2 : base
        nextBreakDoubled = false
        let doubledNote = total != base ? " (doubled)" : ""
        setPhase(pendingBreakPhase, total: total, autoStart: true)
        announce("\(pendingBreakPhase.title) started", "Enjoy \(Self.format(total))\(doubledNote).", pendingBreakPhase)
        notifyOverlay()
    }

    private func beginFocus(autoStart: Bool) {
        awaitingFocusConfirmation = false
        setPhase(.focus, autoStart: autoStart)
        announce("Focus started", autoStart ? "Back to work — \(Self.format(secondsRemaining))." : "Ready when you are.", .focus)
        notifyOverlay()
    }

    private func notifyOverlay() {
        onOverlayStateChanged?()
    }

    private func setPhase(_ newPhase: Phase, total: Int? = nil, autoStart: Bool) {
        phase = newPhase
        let t = total ?? settings.duration(for: newPhase)
        currentPhaseTotal = t
        secondsRemaining = t
        isRunning = autoStart
        if autoStart { startTicker() } else { stopTicker() }
    }

    private func announce(_ title: String, _ body: String, _ phase: Phase) {
        onAnnounce?(title, body, phase)
    }

    // MARK: Ticker

    private func startTicker() {
        stopTicker()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                self?.tick()
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func tick() {
        if breakPromptActive {
            promptCountdownRemaining -= 1
            if promptCountdownRemaining <= 0 {
                breakPromptActive = false
                beginBreak()
            }
            return
        }

        guard isRunning else { return }
        secondsRemaining -= 1
        if secondsRemaining <= 0 {
            completePhase()
        }
    }
}
